import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';

class StorageDetailPage extends StatelessWidget {
  const StorageDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      title: 'Storage Detail',
      child: Center(child: Text('Storage detail placeholder')),
    );
  }
}
