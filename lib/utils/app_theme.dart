import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Cấu hình ColorScheme chuẩn M3
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textInverted,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textInverted,
        tertiary: AppColors.accent, // Dùng màu đỏ gạch làm màu nhấn
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainer: AppColors.surfaceVariant,
        outline: AppColors.outline,
        error: AppColors.error,
      ),

      scaffoldBackgroundColor: AppColors.background,
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h2,
      ),

      // Tối ưu hóa Chip theo chuẩn M3 (Trông mềm mại hơn)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.labelCaps,
        secondaryLabelStyle: AppTextStyles.labelCaps.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: StadiumBorder(side: BorderSide(color: AppColors.outline)),
      ),

      // Nút bấm M3 (Bo tròn nhiều hơn - Stadium shape)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textInverted,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // Input chuẩn M3
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
