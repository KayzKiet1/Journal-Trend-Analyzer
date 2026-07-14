import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../models/trend_data_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../../widgets/horizontal_bar_chart.dart';
import '../../../../widgets/journal_impact_charts.dart';
import '../../../../widgets/year_trend_chart.dart';
import 'journal_detail_chart_range_chip.dart';

class JournalDetailChartsColumn extends StatelessWidget {
  final Journal? journal;
  final List<TrendData> publicationTrends;
  final List<TrendData> citationTrends;
  final List<JournalYearlyData> yearlyData;
  final List<Map<String, dynamic>> topAuthors;
  final int startYear;
  final String rangeLabel;
  final int fullStartYear;
  final int lastTenStartYear;
  final bool isYearlyDataLoading;
  final ValueChanged<int> onStartYearChanged;
  final bool includeAuthors;

  const JournalDetailChartsColumn({
    super.key,
    required this.journal,
    required this.publicationTrends,
    required this.citationTrends,
    required this.yearlyData,
    required this.topAuthors,
    required this.startYear,
    required this.rangeLabel,
    required this.fullStartYear,
    required this.lastTenStartYear,
    required this.isYearlyDataLoading,
    required this.onStartYearChanged,
    this.includeAuthors = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _JournalDetailYearFilter(
          selectedStartYear: startYear,
          fullStartYear: fullStartYear,
          lastTenStartYear: lastTenStartYear,
          onChanged: onStartYearChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            JournalDetailChartRangeChip(rangeLabel: rangeLabel),
            if (isYearlyDataLoading) ...[
              const SizedBox(width: AppSpacing.sm),
              const SizedBox(
                width: 72,
                child: LinearProgressIndicator(minHeight: 3),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        YearTrendChart(
          trends: publicationTrends,
          forceLineChart: true,
          referenceLineStyle: true,
          startYear: startYear,
          title: 'Total Publications',
          valueLabel: 'publications',
        ),
        const SizedBox(height: AppSpacing.lg),
        YearTrendChart(
          trends: citationTrends,
          forceLineChart: true,
          referenceLineStyle: true,
          startYear: startYear,
          title: 'Total Citations',
          valueLabel: 'citations',
        ),
        const SizedBox(height: AppSpacing.lg),
        PublicationCitationTrendChart(
          yearlyData: yearlyData,
          startYear: startYear,
        ),
        const SizedBox(height: AppSpacing.lg),
        CitationsPerPublicationChart(
          yearlyData: yearlyData,
          startYear: startYear,
        ),
        if (includeAuthors) ...[
          const SizedBox(height: AppSpacing.lg),
          HorizontalBarChart(
            data: topAuthors,
            title: 'Top Authors by Publications',
          ),
        ],
      ],
    );
  }
}

class _JournalDetailYearFilter extends StatelessWidget {
  final int selectedStartYear;
  final int fullStartYear;
  final int lastTenStartYear;
  final ValueChanged<int> onChanged;

  const _JournalDetailYearFilter({
    required this.selectedStartYear,
    required this.fullStartYear,
    required this.lastTenStartYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(
          value: fullStartYear,
          icon: const Icon(Icons.timeline, size: 16),
          label: Text('$fullStartYear-now'),
        ),
        const ButtonSegment(
          value: 0,
          icon: Icon(Icons.calendar_view_month, size: 16),
          label: Text('Last 10 years'),
        ),
      ],
      selected: {selectedStartYear == fullStartYear ? fullStartYear : 0},
      onSelectionChanged: (selection) {
        final value = selection.first;
        onChanged(value == fullStartYear ? fullStartYear : lastTenStartYear);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(AppTextStyles.labelCaps),
        foregroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
      ),
    );
  }
}
