import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      title: 'Firestore Collections',
      child: Center(child: Text('Collections placeholder')),
    );
  }
}
