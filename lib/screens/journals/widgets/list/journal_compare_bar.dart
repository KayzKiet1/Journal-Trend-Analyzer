import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class JournalCompareBar extends StatelessWidget {
  final List<Journal> selectedJournals;
  final VoidCallback onClear;
  final VoidCallback? onCompare;

  const JournalCompareBar({
    super.key,
    required this.selectedJournals,
    required this.onClear,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedJournals.length;
    if (selectedCount == 0) return const SizedBox.shrink();

    final canCompare = selectedCount == 2;
    final label = selectedJournals.map((journal) => journal.name).join(' vs ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          const Icon(Icons.compare_arrows, size: 20, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$selectedCount/2 selected',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Clear')),
          const SizedBox(width: AppSpacing.xs),
          FilledButton.icon(
            onPressed: canCompare ? onCompare : null,
            icon: const Icon(Icons.stacked_line_chart, size: 16),
            label: const Text('Compare'),
          ),
        ],
      ),
    );
  }
}
