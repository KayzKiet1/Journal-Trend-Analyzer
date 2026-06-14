import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const AppButton({
    super.key, 
    required this.text, 
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        // Background: accent (Boston Clay #B8422E)
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textInverted,
        disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.2),
        disabledForegroundColor: AppColors.secondary.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(AppSpacing.md),
        // Radius md: 8px
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        // No heavy drop shadows
        elevation: 0,
      ),
      child: Text(
        text,
        style: AppTextStyles.buttonText,
      ),
    );
  }
}
