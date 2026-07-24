import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';

class DocumentDetailPage extends StatelessWidget {
  const DocumentDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Document Detail',
      child: Center(child: Text('Document detail placeholder')),
    );
  }
}
