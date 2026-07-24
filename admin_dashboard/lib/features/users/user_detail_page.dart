import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';

class UserDetailPage extends StatelessWidget {
  const UserDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'User Detail',
      child: Center(child: Text('User detail placeholder')),
    );
  }
}
