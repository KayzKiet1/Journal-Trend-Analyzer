import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  factory AuthenticatedUser.fromFirebaseUser(User user) {
    return AuthenticatedUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Nguoi dung Google',
      photoUrl: user.photoURL,
    );
  }
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static const String _webClientId =
      '419524520507-qelmnva147dqm71nc5ba0javpunlhaoi.apps.googleusercontent.com';

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _isGoogleSignInReady = false;

  AuthenticatedUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : AuthenticatedUser.fromFirebaseUser(user);
  }

  Stream<AuthenticatedUser?> authStateChanges() {
    return _auth.authStateChanges().map((user) {
      return user == null ? null : AuthenticatedUser.fromFirebaseUser(user);
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInReady();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw const AuthServiceException(
          'Thiet bi/nen tang hien tai chua ho tro Google Sign-In.',
        );
      }

      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw const AuthServiceException(
          'Google Sign-In khong tra ve ID token. Hay them SHA-1/SHA-256 '
          'debug vao Firebase Android app, bat Google provider, roi tai '
          'lai file google-services.json.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on AuthServiceException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _firebaseAuthErrorMessage(error),
      );
    } on GoogleSignInException catch (error) {
      throw AuthServiceException(_googleSignInErrorMessage(error));
    } catch (error) {
      throw AuthServiceException('Khong the dang nhap bang Google: $error');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (_isGoogleSignInReady) {
        await _googleSignIn.signOut();
      }
    } catch (error) {
      throw AuthServiceException('Khong the dang xuat: $error');
    }
  }

  Future<void> _ensureGoogleSignInReady() async {
    if (_isGoogleSignInReady) return;
    await _googleSignIn.initialize(serverClientId: _webClientId);
    _isGoogleSignInReady = true;
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException error) {
    final fallback = error.message ?? 'Khong the dang nhap bang Google.';
    if (error.code == 'invalid-credential' ||
        error.code == 'account-exists-with-different-credential') {
      return '$fallback Hay kiem tra Android package name va SHA-1/SHA-256 '
          'cua keystore dang build APK trong Firebase Console.';
    }
    return fallback;
  }

  String _googleSignInErrorMessage(GoogleSignInException error) {
    final description = error.description ?? '';
    final code = error.code;
    if (code == GoogleSignInExceptionCode.canceled) {
      return 'Google Sign-In bi huy hoac bi tu choi sau khi chon tai khoan. '
          'Neu ban khong bam huy, hay them SHA-1/SHA-256 cua may build APK '
          'vao Firebase Android app, tai lai google-services.json, roi build '
          'lai APK.';
    }
    if (code == GoogleSignInExceptionCode.clientConfigurationError ||
        code == GoogleSignInExceptionCode.providerConfigurationError) {
      return 'Cau hinh Google Sign-In chua dung: ${description.isEmpty ? code.name : description}. '
          'Kiem tra package name, web client id va SHA-1/SHA-256 trong Firebase.';
    }
    return description.isEmpty
        ? 'Ban da huy hoac Google Sign-In gap loi.'
        : description;
  }
}
