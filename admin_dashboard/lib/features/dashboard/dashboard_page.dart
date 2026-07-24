import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      title: 'Dashboard',
      child: Center(child: Text('Admin dashboard placeholder')),
    );
  }
}
