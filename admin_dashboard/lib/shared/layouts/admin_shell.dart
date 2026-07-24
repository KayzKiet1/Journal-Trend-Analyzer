import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/repositories/auth_repository.dart';

class AdminShell extends StatelessWidget {
  AdminShell({required this.title, required this.child, super.key})
    : _authRepository = FirebaseAuthRepository();

  final String title;
  final Widget child;
  final AuthRepository _authRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          StreamBuilder(
            stream: _authRepository.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.data == null) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Sign out',
                onPressed: () async {
                  await _authRepository.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AdminRoutes.login,
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
              );
            },
          ),
        ],
      ),
      body: child,
    );
  }
}
