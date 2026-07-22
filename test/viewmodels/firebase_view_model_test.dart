import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/firebase/crashlytics_service.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';
import 'package:journal_trend_analyzer/viewmodels/firebase_view_model.dart';

void main() {
  group('FirebaseViewModel', () {
    test('starts with local Remote Config defaults', () {
      final controller = FirebaseViewModel(
        remoteConfigService: _FakeRemoteConfigService(),
        crashlyticsService: _FakeCrashlyticsService(),
      );

      expect(controller.remoteConfigValues.maxJournalsDisplay, 10);
      expect(controller.remoteConfigValues.maxKeywordsDisplay, 10);
      expect(controller.remoteConfigValues.enableReportExport, isTrue);
      expect(controller.remoteConfigStatus, 'Using default values');
    });

    test('fetchRemoteConfig loads values from service', () async {
      final controller = FirebaseViewModel(
        remoteConfigService: _FakeRemoteConfigService(
          values: const RemoteConfigValues(
            maxJournalsDisplay: 7,
            maxKeywordsDisplay: 8,
            enableReportExport: false,
          ),
        ),
        crashlyticsService: _FakeCrashlyticsService(),
      );

      await controller.fetchRemoteConfig();

      expect(controller.remoteConfigValues.maxJournalsDisplay, 7);
      expect(controller.remoteConfigValues.maxKeywordsDisplay, 8);
      expect(controller.remoteConfigValues.enableReportExport, isFalse);
      expect(
        controller.remoteConfigStatus,
        'Loaded from Firebase Remote Config',
      );
      expect(controller.remoteConfigError, isNull);
      expect(controller.isRemoteConfigLoading, isFalse);
    });

    test('fetchRemoteConfig falls back to defaults on failure', () async {
      final controller = FirebaseViewModel(
        remoteConfigService: _FakeRemoteConfigService(shouldThrow: true),
        crashlyticsService: _FakeCrashlyticsService(),
      );

      await controller.fetchRemoteConfig();

      expect(controller.remoteConfigValues.maxJournalsDisplay, 10);
      expect(controller.remoteConfigValues.maxKeywordsDisplay, 10);
      expect(controller.remoteConfigValues.enableReportExport, isTrue);
      expect(controller.remoteConfigStatus, 'Using default values');
      expect(controller.remoteConfigError, contains('Could not load'));
    });

    test('recordHandledException delegates to Crashlytics service', () async {
      final crashlytics = _FakeCrashlyticsService();
      final controller = FirebaseViewModel(
        remoteConfigService: _FakeRemoteConfigService(),
        crashlyticsService: crashlytics,
      );

      await controller.recordHandledException();

      expect(crashlytics.handledExceptionCount, 1);
      expect(
        controller.crashlyticsMessage,
        'Handled exception sent to Crashlytics.',
      );
      expect(controller.isCrashlyticsLoading, isFalse);
    });

    test('recordHandledException stores error message on failure', () async {
      final controller = FirebaseViewModel(
        remoteConfigService: _FakeRemoteConfigService(),
        crashlyticsService: _FakeCrashlyticsService(shouldThrowHandled: true),
      );

      await controller.recordHandledException();

      expect(controller.crashlyticsMessage, contains('Could not send'));
      expect(controller.isCrashlyticsLoading, isFalse);
    });

    test('triggerTestCrash delegates to Crashlytics service', () async {
      final crashlytics = _FakeCrashlyticsService();
      final controller = FirebaseViewModel(
        remoteConfigService: _FakeRemoteConfigService(),
        crashlyticsService: crashlytics,
      );

      await controller.triggerTestCrash();

      expect(crashlytics.testCrashCount, 1);
    });
  });
}

class _FakeRemoteConfigService implements RemoteConfigClient {
  _FakeRemoteConfigService({this.values, this.shouldThrow = false});

  final RemoteConfigValues? values;
  final bool shouldThrow;

  @override
  Future<RemoteConfigValues> fetchValues() async {
    if (shouldThrow) throw StateError('remote config unavailable');
    return values ?? RemoteConfigService.defaultValues;
  }
}

class _FakeCrashlyticsService implements CrashlyticsClient {
  _FakeCrashlyticsService({this.shouldThrowHandled = false});

  final bool shouldThrowHandled;
  int handledExceptionCount = 0;
  int testCrashCount = 0;

  @override
  Future<void> recordHandledException() async {
    if (shouldThrowHandled) throw StateError('crashlytics unavailable');
    handledExceptionCount++;
  }

  @override
  Future<void> triggerTestCrash() async {
    testCrashCount++;
  }
}
