import '../../data/repositories/auth_repository.dart';

class LoginViewModel {
  LoginViewModel({AuthRepository? authRepository})
    : _authRepository = authRepository ?? FirebaseAuthRepository();

  final AuthRepository _authRepository;

  Future<bool> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    final authState = await _authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return authState.canAccessAdmin;
  }

  Future<bool> signInWithGoogleAsAdmin() async {
    final authState = await _authRepository.signInWithGoogle();
    return authState.canAccessAdmin;
  }
}
