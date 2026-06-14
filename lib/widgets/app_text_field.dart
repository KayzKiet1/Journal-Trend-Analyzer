import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const AppTextField({
    super.key, 
    required this.controller, 
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.bodyLarge,
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.secondary,
        ),
        fillColor: AppColors.surface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14.0,
        ),
        
        // Border: 1px secondary
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.0),
        ),
        
        // Active state: accent (Boston Clay)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
        ),
        
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
      ),
    );
  }
}
