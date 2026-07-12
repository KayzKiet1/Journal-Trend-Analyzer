import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const AppButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: enabled
            ? const LinearGradient(
                colors: [AppColors.accent, AppColors.accentDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : AppColors.secondary.withValues(alpha: 0.18),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : [],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textInverted,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.secondary.withValues(alpha: 0.58),
          padding: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(text, style: AppTextStyles.buttonText),
      ),
    );
  }
}
