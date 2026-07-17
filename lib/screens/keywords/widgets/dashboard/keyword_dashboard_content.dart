import 'package:flutter/material.dart';

import '../../../../models/keyword_dashboard_model.dart';
import '../../../../models/trend_data_model.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../widgets/horizontal_bar_chart.dart';
import '../common/keyword_formatters.dart';
import '../common/keyword_hero.dart';
import '../common/keyword_notice.dart';
import 'keyword_chart_section.dart';
import 'keyword_growth_list.dart';
import 'keyword_metric_grid.dart';
import 'keyword_trend_charts.dart';

class KeywordDashboardContent extends StatelessWidget {
  final String scopeLabel;
  final List<String> topicIds;
  final String topicKey;
  final List<Map<String, dynamic>> topKeywords;
  final List<KeywordGrowthData> keywordGrowth;
  final Map<String, List<TrendData>> keywordTrends;
  final int maxKeywordsDisplay;
  final bool isLoading;
  final String error;
  final VoidCallback onRetry;
  final ValueChanged<Map<String, dynamic>> onKeywordTap;

  const KeywordDashboardContent({
    super.key,
    required this.scopeLabel,
    required this.topicIds,
    required this.topicKey,
    required this.topKeywords,
    required this.keywordGrowth,
    required this.keywordTrends,
    required this.maxKeywordsDisplay,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onKeywordTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleTopKeywords = topKeywords.take(maxKeywordsDisplay).toList();
    final visibleKeywordGrowth = keywordGrowth.take(5).toList();
    final visibleKeywordIds = visibleTopKeywords
        .map((keyword) => keywordId(keyword['id']?.toString() ?? ''))
        .where((id) => id.isNotEmpty)
        .toSet();
    final visibleKeywordTrends = Map<String, List<TrendData>>.fromEntries(
      keywordTrends.entries.where(
        (entry) => visibleKeywordIds.contains(entry.key),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeywordHero(
                eyebrow: 'JOURNAL ARTICLE KEYWORDS',
                title: 'Keyword Insights',
                subtitle: scopeLabel,
                badges: [
                  '${topicIds.length} topic filters',
                  '${visibleTopKeywords.length}/${topKeywords.length} keywords',
                  '${visibleKeywordGrowth.length}/${keywordGrowth.length} tracked',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              KeywordMetricGrid(
                topKeywordCount: visibleTopKeywords.length,
                growthLeaderCount: visibleKeywordGrowth.length,
                trendLineCount: visibleKeywordTrends.length,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (isLoading)
                const KeywordNotice(
                  message: 'Loading keyword trends from OpenAlex...',
                  icon: Icons.sync,
                )
              else if (error.isNotEmpty)
                KeywordNotice(
                  message: error,
                  icon: Icons.error_outline,
                  action: TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                )
              else ...[
                KeywordChartSection(
                  title: 'Keyword Frequency',
                  description:
                      'Shows the most common keywords in this result set. Tap any keyword in the chart or trend list to open the full analysis.',
                  child: HorizontalBarChart(
                    data: visibleTopKeywords,
                    title: 'Keyword frequency (top $maxKeywordsDisplay)',
                    onItemTap: onKeywordTap,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                KeywordChartSection(
                  title: 'Keyword Trend',
                  description:
                      'Preview of the top 5 recent keyword movements. Open a keyword to see exact yearly counts and percentage change.',
                  child: KeywordGrowthList(
                    growth: visibleKeywordGrowth,
                    onKeywordTap: onKeywordTap,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                KeywordTrendCharts(
                  topKeywords: visibleTopKeywords,
                  keywordGrowth: visibleKeywordGrowth,
                  keywordTrends: visibleKeywordTrends,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
