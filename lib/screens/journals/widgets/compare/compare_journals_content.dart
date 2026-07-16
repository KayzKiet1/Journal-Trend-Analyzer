import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../models/trend_data_model.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import 'compare_summary_table.dart';
import 'compare_topic_comparison.dart';
import 'compare_trend_section.dart';
import 'compare_year_filter_toggle.dart';

class CompareJournalsContent extends StatelessWidget {
  final List<Journal> journals;
  final Map<String, List<Map<String, dynamic>>> topicsByJournal;
  final int currentYear;
  final bool excludeFutureYears;
  final ValueChanged<bool> onExcludeFutureYearsChanged;
  final int Function(Journal journal) worksCountForCompare;
  final int Function(Journal journal) citationsForCompare;
  final String Function(Journal journal) avgCitations;
  final List<TrendData> Function(Journal journal) publicationTrends;
  final List<TrendData> Function(Journal journal) citationTrends;

  const CompareJournalsContent({
    super.key,
    required this.journals,
    required this.topicsByJournal,
    required this.currentYear,
    required this.excludeFutureYears,
    required this.onExcludeFutureYearsChanged,
    required this.worksCountForCompare,
    required this.citationsForCompare,
    required this.avgCitations,
    required this.publicationTrends,
    required this.citationTrends,
  });

  @override
  Widget build(BuildContext context) {
    final left = journals[0];
    final right = journals[1];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COMPARISON OVERVIEW', style: AppTextStyles.labelCaps),
              const SizedBox(height: AppSpacing.md),
              CompareSummaryTable(
                left: left,
                right: right,
                currentYear: currentYear,
                excludeFutureYears: excludeFutureYears,
                worksCountForCompare: worksCountForCompare,
                citationsForCompare: citationsForCompare,
                avgCitations: avgCitations,
              ),
              const SizedBox(height: AppSpacing.xl),
              CompareYearFilterToggle(
                currentYear: currentYear,
                value: excludeFutureYears,
                onChanged: onExcludeFutureYearsChanged,
              ),
              const SizedBox(height: AppSpacing.xl),
              CompareTrendSection(
                title: 'PUBLICATION TREND',
                journals: journals,
                trendsBuilder: publicationTrends,
              ),
              const SizedBox(height: AppSpacing.xl),
              CompareTrendSection(
                title: 'CITATION TREND',
                journals: journals,
                trendsBuilder: citationTrends,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('TOP TOPICS', style: AppTextStyles.labelCaps),
              const SizedBox(height: AppSpacing.md),
              CompareTopicComparison(
                journals: journals,
                topicsByJournal: topicsByJournal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
