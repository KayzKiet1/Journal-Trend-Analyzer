import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract class CrashlyticsClient {
  Future<void> recordHandledException();
  Future<void> triggerTestCrash();
}

class CrashlyticsService implements CrashlyticsClient {
  CrashlyticsService({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

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
    }
  }

  @override
  Future<void> triggerTestCrash() async {
    if (kDebugMode) {
      await _crashlytics.recordError(
        StateError('Debug-mode Crashlytics test crash placeholder'),
        StackTrace.current,
        reason: 'Profile Crashlytics Demo: debug-mode test crash',
        fatal: true,
      );
      throw StateError('Debug-mode test crash for Crashlytics demo');
    }

    _crashlytics.crash();
  }
}
