import '../../data/repositories/auth_repository.dart';

class RoleGuard {
  const RoleGuard();

  static Future<bool> isCurrentUserAdmin({
    AuthRepository? authRepository,
    bool forceRefresh = false,
  }) async {
    final repository = authRepository ?? FirebaseAuthRepository();
    final authState = await repository.getCurrentAdminState(
      forceRefresh: forceRefresh,
    );
    return authState.canAccessAdmin;
  }
}
