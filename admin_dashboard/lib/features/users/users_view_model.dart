import 'package:flutter/foundation.dart';

import '../../data/models/admin_user.dart';
import '../../data/repositories/admin_repository.dart';

class UsersViewModel extends ChangeNotifier {
  UsersViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  final List<AdminUser> _users = [];
  String _nextPageToken = '';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  List<AdminUser> get users => List.unmodifiable(_users);

  bool get isLoading => _isLoading;

  bool get isLoadingMore => _isLoadingMore;

  bool get hasMore => _nextPageToken.isNotEmpty;

  String? get errorMessage => _errorMessage;

  Future<void> loadUsers({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh) {
      _users.clear();
      _nextPageToken = '';
    }

    if (_users.isEmpty) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _adminRepository.listUsers(
        pageToken: _nextPageToken.isEmpty ? null : _nextPageToken,
      );
      _users.addAll(result.users);
      _nextPageToken = result.nextPageToken;
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setDisabled(AdminUser user, bool disabled) async {
    await _updateUser(
      _adminRepository.setUserDisabled(uid: user.uid, disabled: disabled),
    );
  }

  Future<void> setAdmin(AdminUser user, bool isAdmin) async {
    await _updateUser(
      _adminRepository.setUserAdminClaim(uid: user.uid, isAdmin: isAdmin),
    );
  }

  Future<void> _updateUser(Future<AdminUser> request) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await request;
      final index = _users.indexWhere((user) => user.uid == updatedUser.uid);
      if (index == -1) {
        _users.insert(0, updatedUser);
      } else {
        _users[index] = updatedUser;
      }
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      notifyListeners();
    }
  }
}
