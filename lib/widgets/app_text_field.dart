import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSuffixTap;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
    this.onChanged,
    this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.bodyLarge,
        cursorColor: AppColors.accent,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted?.call(),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: AppColors.accent, size: 20)
              : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  onPressed: onSuffixTap,
                  icon: Icon(suffixIcon, color: AppColors.secondary, size: 20),
                  tooltip: 'Clear',
                )
              : null,
          hintStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondary.withValues(alpha: 0.8),
          ),
          fillColor: AppColors.surface,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 15.0,
          ),

          // Border: calm neutral with a stronger focus state.
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.border, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.border, width: 1.0),
          ),

          // Active state: accent (Citation Teal)
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.error, width: 1.0),
          ),
        ),
      ),
    );
  }
}
