import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class KeywordEmptyState extends StatelessWidget {
  final String lastSearchText;

  const KeywordEmptyState({super.key, required this.lastSearchText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.manage_search_outlined,
                size: 48,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No keyword analysis yet',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Search journal articles in Home first, then return here.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (lastSearchText.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Last search: $lastSearchText',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
