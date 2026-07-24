import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';

class AppConfigPage extends StatelessWidget {
  const AppConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'App Config',
      child: Center(child: Text('App configuration placeholder')),
    );
  }
}
