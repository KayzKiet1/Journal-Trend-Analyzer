import 'package:flutter/foundation.dart';

import '../../data/models/system_health.dart';
import '../../data/repositories/admin_repository.dart';

class SystemHealthViewModel extends ChangeNotifier {
  SystemHealthViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  SystemHealthSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  SystemHealthSummary? get summary => _summary;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> load({int limit = 25}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _adminRepository.listSystemHealth(limit: limit);
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
