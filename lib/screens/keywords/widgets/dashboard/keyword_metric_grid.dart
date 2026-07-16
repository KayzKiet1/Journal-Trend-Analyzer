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
        'Keywords found',
        compactCount(topKeywordCount),
        Icons.sell_outlined,
      ),
      _KeywordMetricData(
        'Tracked',
        compactCount(growthLeaderCount),
        Icons.trending_up,
      ),
      _KeywordMetricData(
        'Trend charts',
        compactCount(trendLineCount),
        Icons.show_chart,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            Expanded(child: _KeywordMetricTile(metrics[index])),
            if (index != metrics.length - 1)
              Container(
                width: 1,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                color: AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _KeywordMetricTile extends StatelessWidget {
  final _KeywordMetricData metric;

  const _KeywordMetricTile(this.metric);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(metric.icon, color: AppColors.accent, size: 17),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric.value,
                  style: AppTextStyles.h2.copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    metric.label,
                    style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
                    maxLines: 1,
                  ),
                ),
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
