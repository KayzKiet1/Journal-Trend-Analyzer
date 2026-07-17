import 'package:flutter/material.dart';

import '../../../../models/recent_search_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class HomeRecentSearches extends StatelessWidget {
  final List<RecentSearch> history;
  final ValueChanged<RecentSearch> onRecentSearchTap;

  const HomeRecentSearches({
    super.key,
    required this.history,
    required this.onRecentSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final visibleHistory = history.take(6).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.accent, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent searches', style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      'Start from a recent topic.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: visibleHistory
                .map(
                  (search) => _RecentTopicChip(
                    search: search,
                    onPressed: () => onRecentSearchTap(search),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentTopicChip extends StatelessWidget {
  final RecentSearch search;
  final VoidCallback onPressed;

  const _RecentTopicChip({required this.search, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 248),
        child: Text(search.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      onPressed: onPressed,
      avatar: const Icon(Icons.north_west, size: 14),
      backgroundColor: AppColors.surfaceTint,
      surfaceTintColor: AppColors.accentLight,
      elevation: 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      labelStyle: AppTextStyles.labelCaps.copyWith(
        color: AppColors.primary,
        fontSize: 11,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border, width: 1.0),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );
  }
}
