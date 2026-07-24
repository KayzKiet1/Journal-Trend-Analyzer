import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Firestore Documents',
      child: Center(child: Text('Documents placeholder')),
    );
  }
}
