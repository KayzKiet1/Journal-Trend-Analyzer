import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class KeywordNotice extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Widget? action;
  final bool plain;

  const KeywordNotice({
    super.key,
    required this.message,
    this.icon,
    this.action,
    this.plain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: plain ? AppColors.surface : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: plain
          ? Text(message, style: AppTextStyles.bodySmall)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon ?? Icons.info_outline,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(message, style: AppTextStyles.bodySmall)),
                ?action,
              ],
            ),
    );
  }
}
