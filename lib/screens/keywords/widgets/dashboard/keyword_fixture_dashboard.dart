import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../common/keyword_formatters.dart';
import '../common/keyword_section_card.dart';
import 'keyword_dashboard_header.dart';
import 'keyword_metric_grid.dart';

class KeywordFixtureDashboard extends StatelessWidget {
  final List<Map<String, dynamic>> keywords;
  final List<String> topicIds;
  final String scopeLabel;
  final ValueChanged<Map<String, dynamic>> onKeywordTap;

  const KeywordFixtureDashboard({
    super.key,
    required this.keywords,
    required this.topicIds,
    required this.scopeLabel,
    required this.onKeywordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeywordDashboardHeader(
          scopeLabel: scopeLabel,
          stats: [
            '${topicIds.length} topic filters',
            '${keywords.length} top keywords',
            'sample dataset',
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        KeywordMetricGrid(
          topKeywordCount: keywords.length,
          growthLeaderCount: 0,
          trendLineCount: 0,
        ),
        const SizedBox(height: AppSpacing.xl),
        KeywordSectionCard(
          title: 'Keyword Frequency',
          icon: Icons.format_list_numbered,
          child: Column(
            children: keywords.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final keyword = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: InkWell(
                    key: Key('keyword_card_$rank'),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    onTap: () => onKeywordTap(keyword),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              keyword['name'].toString(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            compactCount(
                              (keyword['count'] as num?)?.toInt() ?? 0,
                            ),
                            style: AppTextStyles.labelCaps.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
