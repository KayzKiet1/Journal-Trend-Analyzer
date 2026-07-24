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

  AdminAuthState? get cachedAdminState;

  Future<AdminAuthState> getCurrentAdminState({bool forceRefresh = false});

  Future<AdminAuthState> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AdminAuthState> signInWithGoogle();

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseService.auth;

  final FirebaseAuth _auth;
  static AdminAuthState? _cachedAdminState;
  static String? _cachedAdminUid;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  AdminAuthState? get cachedAdminState {
    final user = _auth.currentUser;
    if (user == null || _cachedAdminUid != user.uid) {
      return null;
    }

    return _cachedAdminState;
  }

  @override
  Future<AdminAuthState> getCurrentAdminState({
    bool forceRefresh = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _clearCachedAdminState();
      return const AdminAuthState(user: null, isAdmin: false);
    }

    if (!forceRefresh &&
        _cachedAdminUid == user.uid &&
        _cachedAdminState != null) {
      return _cachedAdminState!;
    }

    final token = await user.getIdTokenResult(forceRefresh);
    final isAdmin = token.claims?['admin'] == true;
    final adminState = AdminAuthState(user: user, isAdmin: isAdmin);
    _cachedAdminUid = user.uid;
    _cachedAdminState = adminState;
    return adminState;
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
  Future<AdminAuthState> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    await _auth.signInWithPopup(provider);

    final adminState = await getCurrentAdminState(forceRefresh: true);
    if (!adminState.isAdmin) {
      await signOut();
    }

    return adminState;
  }

  @override
  Future<void> signOut() async {
    _clearCachedAdminState();
    await _auth.signOut();
  }

  static void _clearCachedAdminState() {
    _cachedAdminUid = null;
    _cachedAdminState = null;
  }
}
