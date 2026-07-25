import 'package:flutter/material.dart';

final adminThemeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

ThemeData buildAdminTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  const primary = Color(0xFF4F46E5);
  const primarySoft = Color(0xFF7C3AED);
  final secondary = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
  final background = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
  final surface = isDark ? const Color(0xFF111827) : Colors.white;
  final surfaceElevated = isDark
      ? const Color(0xFF172033)
      : const Color(0xFFFFFFFF);
  final border = isDark ? const Color(0xFF263449) : const Color(0xFFE2E8F0);
  final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  final textSecondary = isDark
      ? const Color(0xFFB6C2D1)
      : const Color(0xFF64748B);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
    primary: primary,
    secondary: secondary,
    surface: surface,
    onSurface: textPrimary,
    onSurfaceVariant: textSecondary,
    surfaceContainerLowest: background,
    surfaceContainerLow: surface,
    surfaceContainer: surfaceElevated,
    surfaceContainerHighest: isDark
        ? const Color(0xFF273247)
        : const Color(0xFFE5E7EB),
    outlineVariant: border,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    extensions: [
      AdminGradientTheme(
        shellBackground: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF070B16),
                  Color(0xFF111827),
                  Color(0xFF1E1B4B),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFEEF2FF),
                  Color(0xFFE0F2FE),
                ],
              ),
        sidebarBackground: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF080D19),
                  Color(0xFF111827),
                  Color(0xFF1E1B4B),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF111827),
                  Color(0xFF1E1B4B),
                  Color(0xFF0F172A),
                ],
              ),
        primaryAccent: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), primarySoft],
        ),
      ),
    ],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
        TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
        TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
        TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
        TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: border),
      ),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
      floatingLabelStyle: const TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: border),
        foregroundColor: secondary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
  );
}

class AdminGradientTheme extends ThemeExtension<AdminGradientTheme> {
  const AdminGradientTheme({
    required this.shellBackground,
    required this.sidebarBackground,
    required this.primaryAccent,
  });

  final LinearGradient shellBackground;
  final LinearGradient sidebarBackground;
  final LinearGradient primaryAccent;

  @override
  AdminGradientTheme copyWith({
    LinearGradient? shellBackground,
    LinearGradient? sidebarBackground,
    LinearGradient? primaryAccent,
  }) {
    return AdminGradientTheme(
      shellBackground: shellBackground ?? this.shellBackground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      primaryAccent: primaryAccent ?? this.primaryAccent,
    );
  }

  @override
  AdminGradientTheme lerp(ThemeExtension<AdminGradientTheme>? other, double t) {
    if (other is! AdminGradientTheme) return this;
    return AdminGradientTheme(
      shellBackground: LinearGradient.lerp(
        shellBackground,
        other.shellBackground,
        t,
      )!,
      sidebarBackground: LinearGradient.lerp(
        sidebarBackground,
        other.sidebarBackground,
        t,
      )!,
      primaryAccent: LinearGradient.lerp(primaryAccent, other.primaryAccent, t)!,
    );
  }
}

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
