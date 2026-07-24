import 'package:flutter/foundation.dart';

import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/admin_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  DashboardSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummary? get summary => _summary;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> loadSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _adminRepository.getDashboardSummary();
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
