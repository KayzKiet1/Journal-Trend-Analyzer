import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journal Trend Admin',
      debugShowCheckedModeBanner: false,
      theme: buildAdminTheme(),
      initialRoute: AdminRoutes.dashboard,
      routes: buildAdminRoutes(),
    );
  }
}
