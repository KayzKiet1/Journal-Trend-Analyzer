import 'package:flutter/material.dart';

import '../../../../models/keyword_dashboard_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
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
            'No year-by-year keyword activity is available for this search yet. Try a broader topic or more general keyword.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...growth.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final keyword = entry.value;
          final status = _momentumStatus(keyword);
          final statusColor = _momentumColor(keyword);
          final rangeLabel = keyword.endYear == keyword.startYear
              ? '${keyword.endYear}'
              : '${keyword.startYear}-${keyword.endYear}';

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: statusColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: InkWell(
                onTap: () => onKeywordTap({
                  'id': keyword.id,
                  'name': keyword.name,
                  'count': keyword.totalCount,
                }),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border(
                      left: BorderSide(color: statusColor, width: 4),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      _RankBadge(rank: rank, color: statusColor),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              keyword.name,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$rangeLabel · ${status.description}',
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: Text(
                          status.label,
                          style: AppTextStyles.labelCaps.copyWith(
                            color: statusColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MomentumStatus {
  final String label;
  final String description;

  const _MomentumStatus(this.label, this.description);
}

_MomentumStatus _momentumStatus(KeywordGrowthData keyword) {
  if (keyword.endCount > keyword.startCount) {
    return const _MomentumStatus('Rising', 'more active recently');
  }
  if (keyword.endCount == keyword.startCount) {
    return const _MomentumStatus('Steady', 'similar recent activity');
  }
  return const _MomentumStatus('Cooling', 'less active recently');
}

Color _momentumColor(KeywordGrowthData keyword) {
  if (keyword.endCount > keyword.startCount) return AppColors.accent;
  if (keyword.endCount == keyword.startCount) return AppColors.secondary;
  return AppColors.warning;
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;

  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        '$rank',
        style: AppTextStyles.labelCaps.copyWith(color: color),
      ),
    );
  }
}
