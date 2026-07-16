import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/trend_data_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

/// Widget hiển thị biểu đồ về xu hướng bài báo qua các năm.
class YearTrendChart extends StatelessWidget {
  final List<TrendData> trends;
  final bool forceLineChart;
  final bool referenceLineStyle;
  final int? startYear;
  final String? rangeLabel;
  final String? title;
  final String valueLabel;

  const YearTrendChart({
    super.key,
    required this.trends,
    this.forceLineChart = false,
    this.referenceLineStyle = false,
    this.startYear,
    this.rangeLabel,
    this.title,
    this.valueLabel = 'articles',
  });

  @override
  Widget build(BuildContext context) {
    final visibleTrends =
        trends
            .where(
              (trend) =>
                  trend.year > 0 &&
                  trend.year <= DateTime.now().year &&
                  (startYear == null || trend.year >= startYear!),
            )
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));

    if (visibleTrends.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('No chart data available')),
      );
    }

    bool useLineChart =
        referenceLineStyle || forceLineChart || visibleTrends.length > 50;

    return Container(
      height: 300,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        referenceLineStyle ? AppSpacing.sm : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: referenceLineStyle ? AppColors.border : AppColors.secondary,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          referenceLineStyle
              ? _buildReferenceHeader(
                  title ??
                      (useLineChart ? 'Publication Trend' : 'Articles by Year'),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        title ??
                            (useLineChart
                                ? 'Publication Trend'
                                : 'Articles by Year'),
                        style: AppTextStyles.h2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rangeLabel != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _RangePill(label: rangeLabel!),
                    ],
                  ],
                ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: useLineChart
                ? (referenceLineStyle
                      ? _buildReferenceLineChart(visibleTrends)
                      : _buildLineChart(visibleTrends))
                : _buildBarChart(visibleTrends),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<TrendData> visibleTrends) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            (visibleTrends.map((e) => e.count).reduce((a, b) => a > b ? a : b) *
                    1.2)
                .toDouble(),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: visibleTrends.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.count.toDouble(),
                color: AppColors.accent,
                width: visibleTrends.length > 50
                    ? 2
                    : (visibleTrends.length > 20 ? 4 : 12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppColors.accent,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final year = visibleTrends[group.x.toInt()].year;
              return BarTooltipItem(
                '$year: ${rod.toY.toInt()} $valueLabel',
                AppTextStyles.labelCaps.copyWith(color: AppColors.textInverted),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceHeader(String chartTitle) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Color(0xFF73BF67),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            chartTitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (rangeLabel != null) ...[
          const SizedBox(width: AppSpacing.sm),
          _RangePill(label: rangeLabel!),
          const SizedBox(width: AppSpacing.sm),
        ],
        Icon(Icons.stacked_line_chart, size: 21, color: Colors.black87),
        const SizedBox(width: AppSpacing.md),
        Icon(Icons.grid_on, size: 20, color: Colors.black38),
      ],
    );
  }

  Widget _buildReferenceLineChart(List<TrendData> visibleTrends) {
    final bounds = _AxisBounds.fromValues(
      visibleTrends.map((trend) => trend.count).toList(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxYearLabels = _maxYearLabelsForWidth(constraints.maxWidth);
        final visibleYearIndexes = _visibleYearIndexes(
          visibleTrends.length,
          maxYearLabels,
        );

        return LineChart(
          LineChartData(
            minX: 0,
            maxX: visibleTrends.length > 1 ? visibleTrends.length - 1.0 : 1,
            minY: bounds.minY,
            maxY: bounds.maxY,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: bounds.interval,
              getDrawingHorizontalLine: (value) => FlLine(
                color: const Color(0xFFBDBDBD),
                strokeWidth: 1,
                dashArray: const [2, 3],
              ),
            ),
            titlesData: _buildReferenceTitlesData(
              visibleTrends,
              bounds,
              visibleYearIndexes,
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: visibleTrends.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.count.toDouble(),
                  );
                }).toList(),
                isCurved: false,
                color: const Color(0xFF73BF67),
                barWidth: 3,
                isStrokeCapRound: false,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF73BF67),
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    final year = visibleTrends[spot.x.toInt()].year;
                    return LineTooltipItem(
                      '$year: ${spot.y.toInt()} $valueLabel',
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
    );
  }

  Widget _buildLineChart(List<TrendData> visibleTrends) {
    return LineChart(
      LineChartData(
        maxY:
            (visibleTrends.map((e) => e.count).reduce((a, b) => a > b ? a : b) *
                    1.2)
                .toDouble(),
        gridData: const FlGridData(show: false),
        titlesData: _buildTitlesData(visibleTrends),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: visibleTrends.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.count.toDouble());
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
            getTooltipColor: (spot) => AppColors.accent,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final year = visibleTrends[spot.x.toInt()].year;
                return LineTooltipItem(
                  '$year: ${spot.y.toInt()} $valueLabel',
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
  }

  FlTitlesData _buildReferenceTitlesData(
    List<TrendData> visibleTrends,
    _AxisBounds bounds,
    Set<int> visibleYearIndexes,
  ) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 34,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= visibleTrends.length) {
              return const SizedBox.shrink();
            }
            if (!visibleYearIndexes.contains(index)) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                visibleTrends[index].year.toString(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF4A4A4A),
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          interval: bounds.interval,
          getTitlesWidget: (value, meta) {
            if (value < bounds.minY || value > bounds.maxY) {
              return const SizedBox.shrink();
            }

            return Text(
              value.round().toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF4A4A4A),
                fontSize: 12,
              ),
            );
          },
        ),
      ),
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

  FlTitlesData _buildTitlesData(List<TrendData> visibleTrends) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            int index = value.toInt();
            if (index >= 0 && index < visibleTrends.length) {
              int showEvery = 1;
              if (visibleTrends.length > 40) {
                showEvery = 10;
              } else if (visibleTrends.length > 20) {
                showEvery = 5;
              }

              if (index % showEvery == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    visibleTrends[index].year.toString(),
                    style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}

class _AxisBounds {
  final double minY;
  final double maxY;
  final double interval;

  const _AxisBounds({
    required this.minY,
    required this.maxY,
    required this.interval,
  });

  factory _AxisBounds.fromValues(List<int> values) {
    final minValue = values.reduce((a, b) => a < b ? a : b).toDouble();
    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    final spread = maxValue - minValue;
    final roughInterval = spread <= 0 ? maxValue / 4 : spread / 4;
    final interval = _niceInterval(roughInterval);
    final minY = (minValue / interval).floor() * interval;
    var maxY = (maxValue / interval).ceil() * interval;

    if (maxY <= minY) {
      maxY = minY + interval * 4;
    }

    return _AxisBounds(minY: minY, maxY: maxY, interval: interval);
  }

  static double _niceInterval(double value) {
    if (value <= 0) return 1;

    final magnitude = _pow10(value);
    final normalized = value / magnitude;

    if (normalized <= 1) return magnitude;
    if (normalized <= 2) return magnitude * 2;
    if (normalized <= 5) return magnitude * 5;
    return magnitude * 10;
  }

  static double _pow10(double value) {
    double magnitude = 1;
    while (value >= magnitude * 10) {
      magnitude *= 10;
    }
    while (value < magnitude) {
      magnitude /= 10;
    }
    return magnitude;
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
