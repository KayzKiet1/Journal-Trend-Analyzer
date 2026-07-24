import 'package:cloud_functions/cloud_functions.dart';

import '../../core/firebase/firebase_service.dart';
import '../models/admin_user.dart';
import '../models/dashboard_summary.dart';

class UserListResult {
  const UserListResult({required this.users, required this.nextPageToken});

  final List<AdminUser> users;
  final String nextPageToken;
}

abstract class AdminRepository {
  Future<DashboardSummary> getDashboardSummary();

  Future<UserListResult> listUsers({String? pageToken, int maxResults = 50});

  Future<AdminUser> getUser(String uid);

  Future<AdminUser> setUserDisabled({
    required String uid,
    required bool disabled,
  });

  Future<AdminUser> setUserAdminClaim({
    required String uid,
    required bool isAdmin,
  });
}

class FirebaseAdminRepository implements AdminRepository {
  const FirebaseAdminRepository({FirebaseFunctions? functions})
    : _functions = functions;

  final FirebaseFunctions? _functions;

  FirebaseFunctions get _client => _functions ?? FirebaseService.functions;

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    final data = await _call('getAdminDashboardSummary');
    return DashboardSummary.fromMap(data);
  }

  @override
  Future<UserListResult> listUsers({
    String? pageToken,
    int maxResults = 50,
  }) async {
    final data = await _call('listUsers', {
      'pageToken': pageToken,
      'maxResults': maxResults,
    });
    final users = (data['users'] as List<dynamic>? ?? const [])
        .map(
          (user) => AdminUser.fromMap(Map<String, dynamic>.from(user as Map)),
        )
        .toList();

    return UserListResult(
      users: users,
      nextPageToken: data['nextPageToken']?.toString() ?? '',
    );
  }

  @override
  Future<AdminUser> getUser(String uid) async {
    final data = await _call('getUser', {'uid': uid});
    return AdminUser.fromMap(Map<String, dynamic>.from(data['user'] as Map));
  }

  @override
  Future<AdminUser> setUserDisabled({
    required String uid,
    required bool disabled,
  }) async {
    final data = await _call('setUserDisabled', {
      'uid': uid,
      'disabled': disabled,
    });
    return AdminUser.fromMap(Map<String, dynamic>.from(data['user'] as Map));
  }

  @override
  Future<AdminUser> setUserAdminClaim({
    required String uid,
    required bool isAdmin,
  }) async {
    final data = await _call('setUserAdminClaim', {
      'uid': uid,
      'isAdmin': isAdmin,
    });
    return AdminUser.fromMap(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<Map<String, dynamic>> _call(
    String functionName, [
    Map<String, dynamic>? parameters,
  ]) async {
    try {
      final callable = _client.httpsCallable(functionName);
      final result = await callable.call<Map<String, dynamic>>(
        parameters ?? const {},
      );
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? error.code);
    }
  }
}
