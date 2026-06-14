import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Class cấu hình Theme toàn cục theo hệ thống Heritage.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textInverted,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textInverted,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        outline: AppColors.secondary,
      ),

      // AppBar: Journalistic style (Warm Limestone background, Deep Ink text)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h2,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodySmall,
        labelSmall: AppTextStyles.labelCaps,
      ),

      // Button Theme: Boston Clay (#B8422E)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textInverted,
          textStyle: AppTextStyles.buttonText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),

      // Input Theme: Paper White surface, Sophisticated Slate border
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
        
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
        ),
      ),

      // Card Theme: Level 1 (Paper White surface, 1px Slate border, No shadow)
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.secondary, width: 1.0),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        disabledColor: AppColors.secondary.withValues(alpha: 0.1),
        selectedColor: AppColors.accent,
        secondarySelectedColor: AppColors.accent,
        padding: const EdgeInsets.all(4),
        labelStyle: AppTextStyles.labelCaps,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.secondary, width: 1.0),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}
