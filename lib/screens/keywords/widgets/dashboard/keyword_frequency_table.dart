import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../common/keyword_formatters.dart';
import '../common/keyword_notice.dart';
import '../common/keyword_section_card.dart';

class KeywordFrequencyTable extends StatelessWidget {
  final List<Map<String, dynamic>> topKeywords;
  final ValueChanged<Map<String, dynamic>> onKeywordTap;

  const KeywordFrequencyTable({
    super.key,
    required this.topKeywords,
    required this.onKeywordTap,
  });

  @override
  Widget build(BuildContext context) {
    if (topKeywords.isEmpty) {
      return const KeywordNotice(
        message:
            'No keyword frequency data is available for the selected search.',
      );
    }

    final maxCount = topKeywords
        .map((keyword) => (keyword['count'] as num?)?.toInt() ?? 0)
        .fold<int>(0, (max, count) => count > max ? count : max);

    return KeywordSectionCard(
      title: 'Keyword Occurrences',
      icon: Icons.format_list_numbered,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap a keyword to inspect journals, authors, trends, and related publications for the selected search.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ...topKeywords.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final keyword = entry.value;
            final count = (keyword['count'] as num?)?.toInt() ?? 0;
            final ratio = maxCount == 0 ? 0.0 : count / maxCount;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: InkWell(
                  key: Key('keyword_card_$rank'),
                  onTap: () => onKeywordTap(keyword),
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
                                keyword['name'].toString(),
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
                              compactCount(count),
                              style: AppTextStyles.labelCaps.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
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
          }),
        ],
      ),
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
