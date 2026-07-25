import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/models/app_config.dart';
import '../../data/repositories/admin_repository.dart';

class AppConfigViewModel extends ChangeNotifier {
  AppConfigViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  RemoteAppConfig _remoteConfig = RemoteAppConfig.defaults();
  RemoteConfigVersion? _remoteVersion;
  Map<String, dynamic> _firestoreConfig = {};
  bool _isLoading = false;
  bool _isSavingRemote = false;
  bool _isSavingFirestore = false;
  String? _errorMessage;

  RemoteAppConfig get remoteConfig => _remoteConfig;

  RemoteConfigVersion? get remoteVersion => _remoteVersion;

  Map<String, dynamic> get firestoreConfig =>
      Map.unmodifiable(_firestoreConfig);

  bool get isLoading => _isLoading;

  bool get isSavingRemote => _isSavingRemote;

  bool get isSavingFirestore => _isSavingFirestore;

  bool get isBusy => _isLoading || _isSavingRemote || _isSavingFirestore;

  String? get errorMessage => _errorMessage;

  String get firestoreJsonText {
    return const JsonEncoder.withIndent('  ').convert(_firestoreConfig);
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _adminRepository.getRemoteAppConfig(),
        _adminRepository.getAppConfig(),
      ]);
      final remoteResult = results[0] as RemoteAppConfigResult;
      _remoteConfig = remoteResult.config;
      _remoteVersion = remoteResult.version;
      _firestoreConfig = Map<String, dynamic>.from(results[1] as Map);
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveRemoteConfig(RemoteAppConfig config) async {
    final validationError = validateRemoteConfig(config);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return;
    }

    _isSavingRemote = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _adminRepository.saveRemoteAppConfig(config);
      _remoteConfig = result.config;
      _remoteVersion = result.version;
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isSavingRemote = false;
      notifyListeners();
    }
  }

  Future<void> saveFirestoreConfig(String jsonText) async {
    late final Map<String, dynamic> decoded;
    try {
      final value = jsonDecode(jsonText.trim().isEmpty ? '{}' : jsonText);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Firestore config JSON must be an object.');
      }
      decoded = value;
    } on FormatException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return;
    }

    _isSavingFirestore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _firestoreConfig = await _adminRepository.saveAppConfig(decoded);
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isSavingFirestore = false;
      notifyListeners();
    }
  }

  String? validateRemoteConfig(RemoteAppConfig config) {
    if (config.maxJournalsDisplay < 1 || config.maxJournalsDisplay > 100) {
      return 'Max journals display must be from 1 to 100.';
    }
    if (config.maxKeywordsDisplay < 1 || config.maxKeywordsDisplay > 100) {
      return 'Max keywords display must be from 1 to 100.';
    }
    return null;
  }
}
