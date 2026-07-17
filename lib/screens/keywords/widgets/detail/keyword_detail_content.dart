import 'package:flutter/material.dart';

import '../../../../models/publication_model.dart';
import '../../../../models/trend_data_model.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../../widgets/horizontal_bar_chart.dart';
import '../../../../widgets/year_trend_chart.dart';
import '../common/keyword_formatters.dart';
import '../common/keyword_hero.dart';
import 'keyword_detail_summary.dart';
import 'keyword_publication_section.dart';

class KeywordDetailContent extends StatelessWidget {
  final String keywordName;
  final int keywordCount;
  final List<String> topicIds;
  final String topicLabel;
  final int totalPublications;
  final List<TrendData> trends;
  final List<Map<String, dynamic>> journals;
  final List<Map<String, dynamic>> authors;
  final List<Publication> publications;
  final ValueChanged<Publication> onPublicationTap;

  const KeywordDetailContent({
    super.key,
    required this.keywordName,
    required this.keywordCount,
    required this.topicIds,
    required this.topicLabel,
    required this.totalPublications,
    required this.trends,
    required this.journals,
    required this.authors,
    required this.publications,
    required this.onPublicationTap,
  });

  @override
  Widget build(BuildContext context) {
    final recentTrend = _recentTrendSummary(trends);

    return SingleChildScrollView(
      key: const Key('keyword_detail_content'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeywordHero(
            eyebrow: 'JOURNAL ARTICLE KEYWORD',
            title: keywordName,
            subtitle: topicLabel,
            badges: [
              '${topicIds.length} topic filters',
              '${compactCount(keywordCount)} matches',
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          KeywordDetailSummary(
            totalPublications: totalPublications,
            journalCount: journals.length,
            authorCount: authors.length,
            trendPointCount: trends.length,
            recentTrendLabel: recentTrend.label,
            recentTrendDescription: recentTrend.description,
          ),
          const SizedBox(height: AppSpacing.lg),
          YearTrendChart(
            trends: trends,
            forceLineChart: true,
            title: 'Yearly article activity',
          ),
          const SizedBox(height: AppSpacing.lg),
          HorizontalBarChart(
            data: journals,
            title: 'Journals publishing this keyword',
          ),
          const SizedBox(height: AppSpacing.lg),
          HorizontalBarChart(
            data: authors,
            title: 'Authors using this keyword',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Authors and journals are ranked by matching article count in the current search scope.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          KeywordPublicationSection(
            publications: publications,
            onPublicationTap: onPublicationTap,
          ),
        ],
      ),
    );
  }
}

class _RecentTrendSummary {
  final String label;
  final String description;

  const _RecentTrendSummary({required this.label, required this.description});
}

_RecentTrendSummary _recentTrendSummary(List<TrendData> trends) {
  final latestCompleteYear = DateTime.now().year - 1;
  final recentWindowStartYear = latestCompleteYear - 4;
  final recentTrends =
      trends
          .where((trend) => trend.year >= recentWindowStartYear)
          .where((trend) => trend.year <= latestCompleteYear)
          .where((trend) => trend.count > 0)
          .toList()
        ..sort((a, b) => a.year.compareTo(b.year));

  final comparisonTrends = recentTrends.length >= 2
      ? recentTrends
      : (trends.where((trend) => trend.count > 0).toList()
          ..sort((a, b) => a.year.compareTo(b.year)));

  if (comparisonTrends.length < 2) {
    return const _RecentTrendSummary(
      label: 'No trend',
      description: 'Not enough yearly data for a recent change calculation.',
    );
  }

  final start = comparisonTrends.first;
  final end = comparisonTrends.last;
  if (start.count <= 0) {
    return const _RecentTrendSummary(
      label: 'No trend',
      description: 'Not enough yearly data for a recent change calculation.',
    );
  }

  final change = ((end.count - start.count) / start.count) * 100;
  final sign = change > 0 ? '+' : '';
  return _RecentTrendSummary(
    label: '$sign${change.toStringAsFixed(1)}%',
    description:
        '${start.year}-${end.year}: ${start.count} to ${end.count} articles',
  );
}
