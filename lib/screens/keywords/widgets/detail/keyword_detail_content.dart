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
          KeywordDetailSummary(totalPublications: totalPublications),
          const SizedBox(height: AppSpacing.lg),
          YearTrendChart(
            trends: trends,
            forceLineChart: true,
            title: 'Publication trend over time',
          ),
          const SizedBox(height: AppSpacing.lg),
          HorizontalBarChart(data: journals, title: 'Related journals'),
          const SizedBox(height: AppSpacing.lg),
          HorizontalBarChart(data: authors, title: 'Top authors'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Authors are ranked by the number of matching publications.',
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
