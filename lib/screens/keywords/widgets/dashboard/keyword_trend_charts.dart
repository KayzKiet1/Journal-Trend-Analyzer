import 'package:flutter/material.dart';

import '../../../../models/keyword_dashboard_model.dart';
import '../../../../models/trend_data_model.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../../widgets/year_trend_chart.dart';
import '../common/keyword_formatters.dart';
import '../common/keyword_notice.dart';
import '../common/keyword_section_card.dart';

class KeywordTrendCharts extends StatefulWidget {
  final List<Map<String, dynamic>> topKeywords;
  final List<KeywordGrowthData> keywordGrowth;
  final Map<String, List<TrendData>> keywordTrends;

  const KeywordTrendCharts({
    super.key,
    required this.topKeywords,
    required this.keywordGrowth,
    required this.keywordTrends,
  });

  @override
  State<KeywordTrendCharts> createState() => _KeywordTrendChartsState();
}

class _KeywordTrendChartsState extends State<KeywordTrendCharts> {
  static const int _fullStartYear = 1995;
  late int _startYear = _fullStartYear;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final lastTenStartYear = currentYear - 9;

    if (widget.keywordTrends.isEmpty) {
      return const KeywordNotice(
        message: 'No keyword trend data is available for the selected search.',
      );
    }

    final keywordNamesById = {
      for (final keyword in widget.topKeywords)
        keywordId(keyword['id'].toString()): keyword['name'].toString(),
      for (final keyword in widget.keywordGrowth) keyword.id: keyword.name,
    };

    final visibleTrends = widget.keywordTrends.entries.toList()
      ..sort((a, b) {
        final aTotal = a.value.fold<int>(0, (sum, trend) => sum + trend.count);
        final bTotal = b.value.fold<int>(0, (sum, trend) => sum + trend.count);
        return bTotal.compareTo(aTotal);
      });
    final topVisibleTrends = visibleTrends.take(3).toList();
    final rangeLabel = '$_startYear-$currentYear';

    return KeywordSectionCard(
      title: 'Keyword Activity by Year',
      icon: Icons.show_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KeywordTrendRangeFilter(
            selectedStartYear: _startYear,
            fullStartYear: _fullStartYear,
            lastTenStartYear: lastTenStartYear,
            onChanged: (year) => setState(() => _startYear = year),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Showing yearly article counts for the ${topVisibleTrends.length} keywords with the strongest available trend data in $rangeLabel.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ...topVisibleTrends.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: YearTrendChart(
                trends: entry.value,
                forceLineChart: true,
                startYear: _startYear,
                rangeLabel: rangeLabel,
                title: keywordNamesById[entry.key] ?? entry.key,
                valueLabel: 'articles',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordTrendRangeFilter extends StatelessWidget {
  final int selectedStartYear;
  final int fullStartYear;
  final int lastTenStartYear;
  final ValueChanged<int> onChanged;

  const _KeywordTrendRangeFilter({
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
      ),
    );
  }
}
