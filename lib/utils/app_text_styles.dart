import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  /// H1 - Public Sans, 24px, Bold, primary
  static TextStyle h1 = GoogleFonts.publicSans(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// H2 - Public Sans, 18px, Semi-Bold, primary
  static TextStyle h2 = GoogleFonts.publicSans(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Body Large - Public Sans, 16px, Regular, primary
  static TextStyle bodyLarge = GoogleFonts.publicSans(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  /// Body Small - Public Sans, 14px, Regular, secondary
  static TextStyle bodySmall = GoogleFonts.publicSans(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  /// Label Caps - Space Grotesk, 12px, Bold, secondary
  static TextStyle labelCaps = GoogleFonts.spaceGrotesk(
    fontSize: 12.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  /// Button Text - Public Sans, 16px, Semi-Bold, inverted
  static TextStyle buttonText = GoogleFonts.publicSans(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textInverted,
  );

  // Deprecated/Legacy aliases for compatibility
  static TextStyle get bodyMedium => bodySmall;
  static TextStyle get caption => labelCaps;
  static TextStyle get statValue => h2.copyWith(color: AppColors.accent, fontSize: 22);
}
