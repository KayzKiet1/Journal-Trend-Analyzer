import 'package:flutter/material.dart';

ThemeData buildAdminTheme() {
  const primary = Color(0xFF6366F1); // Indigo 600
  const secondary = Color(0xFF0F172A); // Slate 900
  const background = Color(0xFFF8FAFC); // Slate 50
  const surface = Colors.white;
  const border = Color(0xFFE2E8F0); // Slate 200
  const textPrimary = Color(0xFF0F172A); 
  const textSecondary = Color(0xFF64748B); 

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerLowest: background,
      outlineVariant: border,
    ),
    scaffoldBackgroundColor: background,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _SmoothFadePageTransitionsBuilder(),
        TargetPlatform.iOS: _SmoothFadePageTransitionsBuilder(),
        TargetPlatform.linux: _SmoothFadePageTransitionsBuilder(),
        TargetPlatform.macOS: _SmoothFadePageTransitionsBuilder(),
        TargetPlatform.windows: _SmoothFadePageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
      color: surface,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
      floatingLabelStyle: const TextStyle(
        color: primary,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: border, width: 2),
        foregroundColor: textPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
  );
}

/// Hiệu ứng chuyển trang mượt mà cho Dashboard.
/// Thay thế việc nhảy trang đột ngột bằng hiệu ứng Fade nhẹ 300ms.
class _SmoothFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
      child: child,
    );
  }
}
