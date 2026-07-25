import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: adminThemeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Journal Trend Admin',
          debugShowCheckedModeBanner: false,
          theme: buildAdminTheme(),
          darkTheme: buildAdminTheme(brightness: Brightness.dark),
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 260),
          themeAnimationCurve: Curves.easeInOutCubic,
          initialRoute: AdminRoutes.dashboard,
          routes: buildAdminRoutes(),
        );
      },
    );
  }
}
