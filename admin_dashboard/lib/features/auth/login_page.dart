import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      title: 'Admin Login',
      child: Center(child: Text('Admin login placeholder')),
    );
  }
}
