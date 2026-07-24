import 'package:flutter/foundation.dart';

import '../../data/models/admin_user.dart';
import '../../data/repositories/admin_repository.dart';

class UserDetailViewModel extends ChangeNotifier {
  UserDetailViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  AdminUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AdminUser? get user => _user;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _adminRepository.getUser(uid);
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDisabled(bool disabled) async {
    final currentUser = _user;
    if (currentUser == null) {
      return;
    }
    await _update(
      _adminRepository.setUserDisabled(
        uid: currentUser.uid,
        disabled: disabled,
      ),
    );
  }

  Future<void> setAdmin(bool isAdmin) async {
    final currentUser = _user;
    if (currentUser == null) {
      return;
    }
    await _update(
      _adminRepository.setUserAdminClaim(
        uid: currentUser.uid,
        isAdmin: isAdmin,
      ),
    );
  }

  Future<void> _update(Future<AdminUser> request) async {
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await request;
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      notifyListeners();
    }
  }
}
