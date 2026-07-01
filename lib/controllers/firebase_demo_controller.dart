import 'package:flutter/material.dart';

import '../firebase/crashlytics_service.dart';
import '../firebase/remote_config_service.dart';

class FirebaseDemoController extends ChangeNotifier {
  FirebaseDemoController({
    RemoteConfigClient? remoteConfigService,
    CrashlyticsClient? crashlyticsService,
  }) : _remoteConfigService = remoteConfigService ?? RemoteConfigService(),
       _crashlyticsService = crashlyticsService ?? CrashlyticsService(),
       _remoteConfigValues = RemoteConfigService.defaultValues;

  final RemoteConfigClient _remoteConfigService;
  final CrashlyticsClient _crashlyticsService;

  RemoteConfigValues _remoteConfigValues;
  bool _isRemoteConfigLoading = false;
  String _remoteConfigStatus = 'Using default values';
  String? _remoteConfigError;
  bool _isCrashlyticsLoading = false;
  String? _crashlyticsMessage;

  RemoteConfigValues get remoteConfigValues => _remoteConfigValues;
  bool get isRemoteConfigLoading => _isRemoteConfigLoading;
  String get remoteConfigStatus => _remoteConfigStatus;
  String? get remoteConfigError => _remoteConfigError;
  bool get isCrashlyticsLoading => _isCrashlyticsLoading;
  String? get crashlyticsMessage => _crashlyticsMessage;

  Future<void> fetchRemoteConfig() async {
    _isRemoteConfigLoading = true;
    _remoteConfigError = null;
    _remoteConfigStatus = 'Fetching remote values...';
    notifyListeners();

    try {
      _remoteConfigValues = await _remoteConfigService.fetchValues();
      _remoteConfigStatus = 'Loaded from Firebase Remote Config';
    } catch (error) {
      _remoteConfigValues = RemoteConfigService.defaultValues;
      _remoteConfigStatus = 'Using default values';
      _remoteConfigError = 'Không thể tải Remote Config: $error';
    } finally {
      _isRemoteConfigLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordHandledException() async {
    _isCrashlyticsLoading = true;
    _crashlyticsMessage = null;
    notifyListeners();

    try {
      await _crashlyticsService.recordHandledException();
      _crashlyticsMessage = 'Handled exception đã được gửi lên Crashlytics.';
    } catch (error) {
      _crashlyticsMessage = 'Không thể gửi handled exception: $error';
    } finally {
      _isCrashlyticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> triggerTestCrash() async {
    await _crashlyticsService.triggerTestCrash();
  }
}
