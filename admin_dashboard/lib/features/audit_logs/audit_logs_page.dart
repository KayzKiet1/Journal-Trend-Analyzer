import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      title: 'Audit Logs',
      child: Center(child: Text('Audit logs placeholder')),
    );
  }
}
