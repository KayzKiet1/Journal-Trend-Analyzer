import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/login_page.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';

class AuthGuard extends StatelessWidget {
  AuthGuard({required this.child, super.key, AuthRepository? authRepository})
    : _authRepository = authRepository ?? FirebaseAuthRepository();

  final Widget child;
  final AuthRepository _authRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authRepository.authStateChanges(),
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
          future: _authRepository.getCurrentAdminState(forceRefresh: true),
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
                _authRepository.signOut();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AdminRoutes.login, (route) => false);
              });

              return const LoginPage(
                initialError: 'This account does not have admin access.',
              );
            }

            return child;
          },
        );
      },
    );
  }
}
