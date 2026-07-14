import 'package:flutter/material.dart';

import '../../../../models/keyword_dashboard_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../common/keyword_formatters.dart';
import '../common/keyword_notice.dart';

class KeywordGrowthList extends StatelessWidget {
  final List<KeywordGrowthData> growth;
  final ValueChanged<Map<String, dynamic>> onKeywordTap;

  const KeywordGrowthList({
    super.key,
    required this.growth,
    required this.onKeywordTap,
  });

  @override
  Widget build(BuildContext context) {
    if (growth.isEmpty) {
      return const KeywordNotice(
        message:
            'Not enough year-by-year keyword data to calculate positive growth for this search.',
      );
    }

    final maxGrowth = growth
        .map((keyword) => keyword.growthRate)
        .fold<double>(0, (max, value) => value > max ? value : max);

    return Column(
      children: growth.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final keyword = entry.value;
        final ratio = maxGrowth <= 0 ? 0.0 : keyword.growthRate / maxGrowth;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Material(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: InkWell(
              onTap: () => onKeywordTap({
                'id': keyword.id,
                'name': keyword.name,
                'count': keyword.totalCount,
              }),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _RankBadge(rank: rank),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            keyword.name,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '+${keyword.growthRate.toStringAsFixed(1)}%',
                          style: AppTextStyles.labelCaps.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${keyword.startYear}: ${compactCount(keyword.startCount)} -> '
                      '${keyword.endYear}: ${compactCount(keyword.endCount)}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: ratio.clamp(0.0, 1.0),
                        color: AppColors.accent,
                        backgroundColor: AppColors.accentLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        '$rank',
        style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent),
      ),
    );
  }
}
