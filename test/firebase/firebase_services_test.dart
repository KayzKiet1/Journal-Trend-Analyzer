import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:journal_trend_analyzer/firebase/crashlytics_service.dart';
import 'package:journal_trend_analyzer/firebase/firebase_auth_service.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 1),
        minimumFetchInterval: Duration.zero,
      ),
    );
    registerFallbackValue(StackTrace.current);
  });

  group('RemoteConfigService', () {
    test(
      'fetchValues sets defaults, fetches and maps positive values',
      () async {
        final remoteConfig = _MockFirebaseRemoteConfig();
        when(() => remoteConfig.setDefaults(any())).thenAnswer((_) async {});
        when(
          () => remoteConfig.setConfigSettings(any()),
        ).thenAnswer((_) async {});
        when(remoteConfig.fetchAndActivate).thenAnswer((_) async => true);
        when(() => remoteConfig.getInt('max_journals_display')).thenReturn(7);
        when(() => remoteConfig.getInt('max_keywords_display')).thenReturn(9);
        when(
          () => remoteConfig.getBool('enable_report_export'),
        ).thenReturn(false);

        final values = await RemoteConfigService(
          remoteConfig: remoteConfig,
        ).fetchValues();

        expect(values.maxJournalsDisplay, 7);
        expect(values.maxKeywordsDisplay, 9);
        expect(values.enableReportExport, isFalse);
        verify(
          () => remoteConfig.setDefaults({
            'max_journals_display': 10,
            'max_keywords_display': 10,
            'enable_report_export': true,
          }),
        ).called(1);
        verify(remoteConfig.fetchAndActivate).called(1);
      },
    );

    test('currentValues falls back when numeric values are not positive', () {
      final remoteConfig = _MockFirebaseRemoteConfig();
      when(() => remoteConfig.getInt('max_journals_display')).thenReturn(0);
      when(() => remoteConfig.getInt('max_keywords_display')).thenReturn(-3);
      when(() => remoteConfig.getBool('enable_report_export')).thenReturn(true);

      final values = RemoteConfigService(
        remoteConfig: remoteConfig,
      ).currentValues();

      expect(values.maxJournalsDisplay, 10);
      expect(values.maxKeywordsDisplay, 10);
      expect(values.enableReportExport, isTrue);
    });
  });

  group('CrashlyticsService', () {
    test('recordHandledException sends a non-fatal handled error', () async {
      final crashlytics = _MockFirebaseCrashlytics();
      when(
        () => crashlytics.recordError(
          any(),
          any(),
          reason: any(named: 'reason'),
          fatal: any(named: 'fatal'),
        ),
      ).thenAnswer((_) async {});

      await CrashlyticsService(
        crashlytics: crashlytics,
      ).recordHandledException();

      final verification = verify(
        () => crashlytics.recordError(
          captureAny(),
          any(),
          reason: 'Profile Crashlytics Demo: handled exception',
          fatal: false,
        ),
      );
      verification.called(1);
      expect(verification.captured[0], isA<StateError>());
    });

    test(
      'triggerTestCrash records a debug fatal placeholder then throws',
      () async {
        final crashlytics = _MockFirebaseCrashlytics();
        when(
          () => crashlytics.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
          ),
        ).thenAnswer((_) async {});

        await expectLater(
          CrashlyticsService(crashlytics: crashlytics).triggerTestCrash(),
          throwsA(isA<StateError>()),
        );

        verify(
          () => crashlytics.recordError(
            any(),
            any(),
            reason: 'Profile Crashlytics Demo: debug-mode test crash',
            fatal: true,
          ),
        ).called(1);
      },
    );
  });

  group('FirebaseAuthService', () {
    test('AuthenticatedUser maps Firebase user fields', () {
      final user = _MockUser();
      when(() => user.uid).thenReturn('U1');
      when(() => user.email).thenReturn('student@example.com');
      when(() => user.displayName).thenReturn('Student Name');
      when(() => user.photoURL).thenReturn('https://example.com/photo.png');

      final mapped = AuthenticatedUser.fromFirebaseUser(user);

      expect(mapped.uid, 'U1');
      expect(mapped.email, 'student@example.com');
      expect(mapped.displayName, 'Student Name');
      expect(mapped.photoUrl, 'https://example.com/photo.png');
    });

    test(
      'currentUser and authStateChanges map nullable Firebase users',
      () async {
        final auth = _MockFirebaseAuth();
        final googleSignIn = _MockGoogleSignIn();
        final user = _MockUser();
        final controller = StreamController<User?>.broadcast();
        when(() => user.uid).thenReturn('U2');
        when(() => user.email).thenReturn(null);
        when(() => user.displayName).thenReturn(null);
        when(() => user.photoURL).thenReturn(null);
        when(() => auth.currentUser).thenReturn(user);
        when(auth.authStateChanges).thenAnswer((_) => controller.stream);

        final service = FirebaseAuthService(
          auth: auth,
          googleSignIn: googleSignIn,
        );

        expect(service.currentUser?.displayName, 'Nguoi dung Google');

        final events = <AuthenticatedUser?>[];
        final subscription = service.authStateChanges().listen(events.add);
        controller
          ..add(user)
          ..add(null);
        await Future<void>.delayed(Duration.zero);

        expect(events.first?.uid, 'U2');
        expect(events.first?.email, isEmpty);
        expect(events.last, isNull);
        await subscription.cancel();
        await controller.close();
      },
    );

    test('signOut signs out Firebase and wraps failures', () async {
      final auth = _MockFirebaseAuth();
      final googleSignIn = _MockGoogleSignIn();
      when(auth.signOut).thenAnswer((_) async {});

      final service = FirebaseAuthService(
        auth: auth,
        googleSignIn: googleSignIn,
      );
      await service.signOut();
      verify(auth.signOut).called(1);

      when(auth.signOut).thenThrow(StateError('network down'));
      await expectLater(
        service.signOut(),
        throwsA(
          isA<AuthServiceException>().having(
            (error) => error.toString(),
            'message',
            contains('Khong the dang xuat'),
          ),
        ),
      );
    });

    test('signInWithGoogle reports unsupported platform clearly', () async {
      final auth = _MockFirebaseAuth();
      final googleSignIn = _MockGoogleSignIn();
      when(
        () => googleSignIn.initialize(
          serverClientId: any(named: 'serverClientId'),
        ),
      ).thenAnswer((_) async {});
      when(googleSignIn.supportsAuthenticate).thenReturn(false);

      final service = FirebaseAuthService(
        auth: auth,
        googleSignIn: googleSignIn,
      );

      await expectLater(
        service.signInWithGoogle(),
        throwsA(
          isA<AuthServiceException>().having(
            (error) => error.toString(),
            'message',
            contains('chua ho tro Google Sign-In'),
          ),
        ),
      );
    });
  });
}

class _MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class _MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockUser extends Mock implements User {}
