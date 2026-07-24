import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/repositories/admin_repository.dart';

class AppConfigViewModel extends ChangeNotifier {
  AppConfigViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  Map<String, dynamic> _config = {};
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get config => Map.unmodifiable(_config);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get jsonText => const JsonEncoder.withIndent('  ').convert(_config);

  Future<void> loadConfig() async {
    await _run(() async {
      _config = await _adminRepository.getAppConfig();
    });
  }

  Future<void> saveConfig(String jsonText) async {
    late final Map<String, dynamic> decoded;
    try {
      final value = jsonDecode(jsonText);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('App config JSON must be an object.');
      }
      decoded = value;
    } on FormatException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return;
    }

    await _run(() async {
      _config = await _adminRepository.saveAppConfig(decoded);
    });
  }

  Future<void> saveTypedConfig({
    required bool maintenanceMode,
    required bool enableReportExport,
    required int maxJournalsDisplay,
    required String announcementText,
    required String advancedJson,
  }) async {
    if (maxJournalsDisplay < 1) {
      _errorMessage = 'Max journals display must be greater than 0.';
      notifyListeners();
      return;
    }

    Map<String, dynamic> advancedConfig = {};
    try {
      final decoded = jsonDecode(
        advancedJson.trim().isEmpty ? '{}' : advancedJson,
      );
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Advanced config JSON must be an object.');
      }
      advancedConfig = decoded;
    } on FormatException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return;
    }

    await _run(() async {
      _config = await _adminRepository.saveAppConfig({
        ...advancedConfig,
        'maintenanceMode': maintenanceMode,
        'enableReportExport': enableReportExport,
        'maxJournalsDisplay': maxJournalsDisplay,
        'announcementText': announcementText,
      });
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
