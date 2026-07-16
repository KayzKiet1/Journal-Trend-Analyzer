import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../common/keyword_formatters.dart';

class KeywordMetricGrid extends StatelessWidget {
  final int topKeywordCount;
  final int growthLeaderCount;
  final int trendLineCount;

  const KeywordMetricGrid({
    super.key,
    required this.topKeywordCount,
    required this.growthLeaderCount,
    required this.trendLineCount,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _KeywordMetricData(
        'Top Keywords',
        compactCount(topKeywordCount),
        Icons.sell_outlined,
      ),
      _KeywordMetricData(
        'Growth Leaders',
        compactCount(growthLeaderCount),
        Icons.trending_up,
      ),
      _KeywordMetricData(
        'Trend Lines',
        compactCount(trendLineCount),
        Icons.show_chart,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 620;
        return GridView.count(
          crossAxisCount: isWide ? 3 : 1,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isWide ? 2.4 : 3.6,
          children: metrics
              .map((metric) => _KeywordMetricTile(metric))
              .toList(),
        );
      },
    );
  }
}

class _KeywordMetricTile extends StatelessWidget {
  final _KeywordMetricData metric;

  const _KeywordMetricTile(this.metric);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(metric.icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(metric.value, style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.xs),
                Text(metric.label, style: AppTextStyles.labelCaps),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordMetricData {
  final String label;
  final String value;
  final IconData icon;

  const _KeywordMetricData(this.label, this.value, this.icon);
}
