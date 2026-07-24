import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';

class StoragePage extends StatelessWidget {
  const StoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Storage',
      child: Center(child: Text('Storage management placeholder')),
    );
  }
}
