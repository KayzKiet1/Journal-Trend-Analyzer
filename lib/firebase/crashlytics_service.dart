import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract class CrashlyticsClient {
  Future<void> recordHandledException();
  Future<void> triggerTestCrash();
}

class CrashlyticsService implements CrashlyticsClient {
  CrashlyticsService({
    FirebaseCrashlytics? crashlytics,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseCrashlytics _crashlytics;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<void> recordHandledException() async {
    try {
      throw StateError('Handled Crashlytics demo exception');
    } catch (error, stackTrace) {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: 'Profile Crashlytics Demo: handled exception',
        fatal: false,
      );
      await _recordAppError(
        title: 'Handled Crashlytics demo exception',
        message: error.toString(),
        severity: 'warning',
        fatal: false,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> triggerTestCrash() async {
    if (kDebugMode) {
      await _recordAppError(
        title: 'Debug-mode Crashlytics test crash',
        message: 'Debug-mode test crash for Crashlytics demo',
        severity: 'fatal',
        fatal: true,
        stackTrace: StackTrace.current,
      );
      await _crashlytics.recordError(
        StateError('Debug-mode Crashlytics test crash placeholder'),
        StackTrace.current,
        reason: 'Profile Crashlytics Demo: debug-mode test crash',
        fatal: true,
      );
      throw StateError('Debug-mode test crash for Crashlytics demo');
    }

    await _recordAppError(
      title: 'Crashlytics test crash',
      message: 'Release-mode test crash for Crashlytics demo',
      severity: 'fatal',
      fatal: true,
      stackTrace: StackTrace.current,
    );
    _crashlytics.crash();
  }

  Future<void> _recordAppError({
    required String title,
    required String message,
    required String severity,
    required bool fatal,
    required StackTrace stackTrace,
  }) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('app_errors').add({
        'title': title,
        'message': message,
        'severity': severity,
        'status': 'open',
        'module': 'firebase_test',
        'feature': 'profile_crashlytics_panel',
        'screen': 'Profile',
        'fatal': fatal,
        'userId': user?.uid ?? '',
        'userEmail': user?.email ?? '',
        'platform': defaultTargetPlatform.name,
        'isDebugMode': kDebugMode,
        'stackTrace': stackTrace.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('Could not write app_errors health event: $error');
    }
  }
}
