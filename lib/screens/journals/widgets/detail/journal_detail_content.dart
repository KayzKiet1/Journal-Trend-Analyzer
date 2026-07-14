import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../models/trend_data_model.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../widgets/horizontal_bar_chart.dart';
import 'journal_detail_charts_column.dart';
import 'journal_detail_header.dart';
import 'journal_detail_metadata_card.dart';
import 'journal_detail_scope_banner.dart';
import 'journal_detail_stats_card.dart';
import 'journal_detail_topic_list.dart';

class JournalDetailContent extends StatelessWidget {
  final Journal? journal;
  final String fallbackName;
  final String? topicLabel;
  final List<TrendData> publicationTrends;
  final List<TrendData> citationTrends;
  final List<JournalYearlyData> yearlyData;
  final List<Map<String, dynamic>> topTopics;
  final List<Map<String, dynamic>> topAuthors;
  final int chartStartYear;
  final String chartRangeLabel;
  final int fullChartStartYear;
  final int lastTenChartStartYear;
  final bool isYearlyDataLoading;
  final ValueChanged<int> onChartStartYearChanged;
  final bool isFavorite;
  final ValueChanged<Journal> onToggleFavorite;
  final ValueChanged<String?> onOpenLink;

  const JournalDetailContent({
    super.key,
    required this.journal,
    required this.fallbackName,
    required this.topicLabel,
    required this.publicationTrends,
    required this.citationTrends,
    required this.yearlyData,
    required this.topTopics,
    required this.topAuthors,
    required this.chartStartYear,
    required this.chartRangeLabel,
    required this.fullChartStartYear,
    required this.lastTenChartStartYear,
    required this.isYearlyDataLoading,
    required this.onChartStartYearChanged,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JournalDetailHeader(
          journal: journal,
          fallbackName: fallbackName,
          isFavorite: isFavorite,
          onToggleFavorite: onToggleFavorite,
          onOpenLink: onOpenLink,
        ),
        if (topicLabel != null && topicLabel!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          JournalDetailScopeBanner(topicLabel: topicLabel!),
        ],
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 700;
            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: JournalDetailChartsColumn(
                      journal: journal,
                      publicationTrends: publicationTrends,
                      citationTrends: citationTrends,
                      yearlyData: yearlyData,
                      topAuthors: topAuthors,
                      startYear: chartStartYear,
                      rangeLabel: chartRangeLabel,
                      fullStartYear: fullChartStartYear,
                      lastTenStartYear: lastTenChartStartYear,
                      isYearlyDataLoading: isYearlyDataLoading,
                      onStartYearChanged: onChartStartYearChanged,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        JournalDetailStatsCard(journal: journal),
                        const SizedBox(height: AppSpacing.lg),
                        JournalDetailTopicList(topics: topTopics),
                        const SizedBox(height: AppSpacing.lg),
                        JournalDetailMetadataCard(
                          journal: journal,
                          onOpenLink: onOpenLink,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                JournalDetailStatsCard(journal: journal),
                const SizedBox(height: AppSpacing.lg),
                JournalDetailChartsColumn(
                  journal: journal,
                  publicationTrends: publicationTrends,
                  citationTrends: citationTrends,
                  yearlyData: yearlyData,
                  topAuthors: topAuthors,
                  startYear: chartStartYear,
                  rangeLabel: chartRangeLabel,
                  fullStartYear: fullChartStartYear,
                  lastTenStartYear: lastTenChartStartYear,
                  isYearlyDataLoading: isYearlyDataLoading,
                  onStartYearChanged: onChartStartYearChanged,
                  includeAuthors: false,
                ),
                const SizedBox(height: AppSpacing.lg),
                JournalDetailTopicList(topics: topTopics),
                const SizedBox(height: AppSpacing.lg),
                HorizontalBarChart(
                  data: topAuthors,
                  title: 'Top Authors by Publications',
                ),
                const SizedBox(height: AppSpacing.lg),
                JournalDetailMetadataCard(
                  journal: journal,
                  onOpenLink: onOpenLink,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
