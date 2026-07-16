import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/journal_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

class CitationsPerPublicationChart extends StatelessWidget {
  final List<JournalYearlyData> yearlyData;
  final int? startYear;
  final String? rangeLabel;

  const CitationsPerPublicationChart({
    super.key,
    required this.yearlyData,
    this.startYear,
    this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final points =
        yearlyData
            .where(
              (item) =>
                  item.year > 0 &&
                  item.year <= currentYear &&
                  (startYear == null || item.year >= startYear!) &&
                  item.worksCount > 0,
            )
            .map(
              (item) => _ImpactPoint(
                year: item.year,
                value: item.citedByCount / item.worksCount,
              ),
            )
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));

    if (points.isEmpty) {
      return _EmptyChartCard(
        title: 'Citations per Publication by Year',
        message: 'No yearly citation-per-publication data available.',
      );
    }

    final maxY = points
        .map((point) => point.value)
        .reduce((a, b) => a > b ? a : b);

    return _ChartCard(
      title: 'Citations per Publication by Year',
      rangeLabel: rangeLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final visibleYearIndexes = _visibleYearIndexes(
            points.length,
            _maxYearLabelsForWidth(constraints.maxWidth),
          );

          return LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY <= 0 ? 1 : maxY * 1.2,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              titlesData: _buildTitles(points, visibleYearIndexes),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: points.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.value);
                  }).toList(),
                  isCurved: true,
                  color: AppColors.accent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.accent.withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.accent,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final point = points[spot.x.toInt()];
                      return LineTooltipItem(
                        '${point.year}: ${point.value.toStringAsFixed(2)} citations/pub',
                        AppTextStyles.labelCaps.copyWith(
                          color: AppColors.textInverted,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PublicationCitationTrendChart extends StatelessWidget {
  final List<JournalYearlyData> yearlyData;
  final int? startYear;
  final String? rangeLabel;

  const PublicationCitationTrendChart({
    super.key,
    required this.yearlyData,
    this.startYear,
    this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final points =
        yearlyData
            .where(
              (item) =>
                  item.year > 0 &&
                  item.year <= currentYear &&
                  (startYear == null || item.year >= startYear!) &&
                  (item.worksCount > 0 || item.citedByCount > 0),
            )
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));

    if (points.isEmpty) {
      return const _EmptyChartCard(
        title: 'Publication vs Citation Trend',
        message: 'No yearly publication and citation data available.',
      );
    }

    final maxWorks = points
        .map((point) => point.worksCount)
        .reduce((a, b) => a > b ? a : b);
    final maxCitations = points
        .map((point) => point.citedByCount)
        .reduce((a, b) => a > b ? a : b);

    double normalize(int value, int maxValue) {
      if (maxValue <= 0) return 0;
      return (value / maxValue) * 100;
    }

    return _ChartCard(
      title: 'Publication vs Citation Trend',
      rangeLabel: rangeLabel,
      trailing: Wrap(
        spacing: AppSpacing.sm,
        children: const [
          _LegendDot(label: 'Publications', color: AppColors.accent),
          _LegendDot(label: 'Citations', color: AppColors.primarySoft),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final visibleYearIndexes = _visibleYearIndexes(
            points.length,
            _maxYearLabelsForWidth(constraints.maxWidth),
          );

          return LineChart(
            LineChartData(
              minY: 0,
              maxY: 110,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              titlesData: _buildTitles(points, visibleYearIndexes),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: points.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      normalize(entry.value.worksCount, maxWorks),
                    );
                  }).toList(),
                  isCurved: true,
                  color: AppColors.accent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: points.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      normalize(entry.value.citedByCount, maxCitations),
                    );
                  }).toList(),
                  isCurved: true,
                  color: AppColors.primarySoft,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.primary,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final point = points[spot.x.toInt()];
                      final isCitationSeries = spot.barIndex == 1;
                      final label = isCitationSeries
                          ? '${point.citedByCount} citations'
                          : '${point.worksCount} publications';
                      return LineTooltipItem(
                        '${point.year}: $label',
                        AppTextStyles.labelCaps.copyWith(
                          color: AppColors.textInverted,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final String? rangeLabel;

  const _ChartCard({
    required this.title,
    required this.child,
    this.trailing,
    this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(title, style: AppTextStyles.h2)),
              if (rangeLabel != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _RangePill(label: rangeLabel!),
              ],
              if (trailing != null) const SizedBox(width: AppSpacing.sm),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EmptyChartCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyChartCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: title,
      child: Center(child: Text(message, style: AppTextStyles.bodySmall)),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.labelCaps.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _RangePill extends StatelessWidget {
  final String label;

  const _RangePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelCaps.copyWith(
          color: AppColors.accentDark,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ImpactPoint {
  final int year;
  final double value;

  const _ImpactPoint({required this.year, required this.value});
}

FlTitlesData _buildTitles(List<dynamic> points, Set<int> visibleYearIndexes) {
  return FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < 0 || index >= points.length) {
            return const SizedBox.shrink();
          }

          if (!visibleYearIndexes.contains(index)) {
            return const SizedBox.shrink();
          }

          final year = points[index].year;
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              year.toString(),
              style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
            ),
          );
        },
      ),
    ),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}

int _maxYearLabelsForWidth(double width) {
  if (width < 260) return 3;
  if (width < 360) return 4;
  if (width < 520) return 5;
  if (width < 700) return 6;
  return 7;
}

Set<int> _visibleYearIndexes(int pointCount, int maxLabels) {
  if (pointCount <= maxLabels) {
    return {for (int i = 0; i < pointCount; i++) i};
  }

  final lastIndex = pointCount - 1;
  final selected = <int>{0, lastIndex};
  final segments = maxLabels - 1;

  for (int i = 1; i < segments; i++) {
    selected.add((lastIndex * i / segments).round());
  }

  return selected;
}
