import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/router.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/login_page.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';

class AuthGuard extends StatefulWidget {
  AuthGuard({required this.child, super.key, AuthRepository? authRepository})
    : _authRepository = authRepository ?? FirebaseAuthRepository();

  final Widget child;
  final AuthRepository _authRepository;

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  Future<AdminAuthState>? _adminStateFuture;
  String? _adminStateUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: widget._authRepository.currentUser,
      stream: widget._authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }

        if (snapshot.hasError) {
          return ErrorView(message: snapshot.error.toString());
        }

        if (snapshot.data == null) {
          return const LoginPage();
        }

        return FutureBuilder(
          initialData: widget._authRepository.cachedAdminState,
          future: _getAdminState(snapshot.data!),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }

            if (adminSnapshot.hasError) {
              return ErrorView(message: adminSnapshot.error.toString());
            }

            final adminState = adminSnapshot.data;
            if (adminState == null || !adminState.canAccessAdmin) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget._authRepository.signOut();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AdminRoutes.login, (route) => false);
              });

              return const LoginPage(
                initialError: 'This account does not have admin access.',
              );
            }

            return widget.child;
          },
        );
      },
    );
  }

  Future<AdminAuthState> _getAdminState(User user) {
    if (_adminStateFuture == null || _adminStateUid != user.uid) {
      _adminStateUid = user.uid;
      _adminStateFuture = widget._authRepository.getCurrentAdminState();
    }

    return _adminStateFuture!;
  }
}
