import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class JournalDetailChartRangeChip extends StatelessWidget {
  final String rangeLabel;

  const JournalDetailChartRangeChip({super.key, required this.rangeLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range, size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Chart range',
            style: AppTextStyles.labelCaps.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            rangeLabel,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
