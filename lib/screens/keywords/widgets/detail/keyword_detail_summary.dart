import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../common/keyword_formatters.dart';
import '../common/keyword_section_card.dart';

class KeywordDetailSummary extends StatelessWidget {
  final int totalPublications;
  final int journalCount;
  final int authorCount;
  final int trendPointCount;
  final String recentTrendLabel;
  final String recentTrendDescription;

  const KeywordDetailSummary({
    super.key,
    required this.totalPublications,
    required this.journalCount,
    required this.authorCount,
    required this.trendPointCount,
    required this.recentTrendLabel,
    required this.recentTrendDescription,
  });

  @override
  Widget build(BuildContext context) {
    return KeywordSectionCard(
      title: 'Keyword Role',
      icon: Icons.radar_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Use this page to see where the keyword appears, who publishes with it, and which articles are worth opening next.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Articles',
                  value: compactCount(totalPublications),
                  icon: Icons.article_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryTile(
                  label: 'Journals',
                  value: compactCount(journalCount),
                  icon: Icons.menu_book_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryTile(
                  label: 'Change',
                  value: recentTrendLabel,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            trendPointCount == 0
                ? 'No yearly activity points are available for this keyword yet.'
                : '$recentTrendDescription · $trendPointCount yearly points available.',
            style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Top authors available: ${compactCount(authorCount)}',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
