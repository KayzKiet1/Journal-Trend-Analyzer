import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      title: 'Users',
      child: Center(child: Text('Users management placeholder')),
    );
  }
}
