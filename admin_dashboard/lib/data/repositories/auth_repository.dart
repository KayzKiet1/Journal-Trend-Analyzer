import 'package:firebase_auth/firebase_auth.dart';

import '../../core/firebase/firebase_service.dart';

class AdminAuthState {
  const AdminAuthState({required this.user, required this.isAdmin});

  final User? user;
  final bool isAdmin;

  bool get canAccessAdmin => user != null && isAdmin;
}

abstract class AuthRepository {
  Stream<User?> authStateChanges();

  User? get currentUser;

  Future<AdminAuthState> getCurrentAdminState({bool forceRefresh = false});

  Future<AdminAuthState> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseService.auth;

  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<AdminAuthState> getCurrentAdminState({
    bool forceRefresh = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AdminAuthState(user: null, isAdmin: false);
    }

    final token = await user.getIdTokenResult(forceRefresh);
    final isAdmin = token.claims?['admin'] == true;
    return AdminAuthState(user: user, isAdmin: isAdmin);
  }

  @override
  Future<AdminAuthState> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final adminState = await getCurrentAdminState(forceRefresh: true);
    if (!adminState.isAdmin) {
      await signOut();
    }

    return adminState;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
