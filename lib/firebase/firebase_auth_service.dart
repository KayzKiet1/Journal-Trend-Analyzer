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
        error.message ?? 'Khong the dang nhap bang Google.',
      );
    } on GoogleSignInException catch (error) {
      throw AuthServiceException(
        error.description ?? 'Ban da huy hoac Google Sign-In gap loi.',
      );
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
    await _googleSignIn.initialize();
    _isGoogleSignInReady = true;
  }
}
