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
  final String? title;

  const YearTrendChart({
    super.key, 
    required this.trends,
    this.forceLineChart = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text("Không có dữ liệu biểu đồ")),
      );
    }

    bool useLineChart = forceLineChart || trends.length > 50;

    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? (useLineChart ? 'Publication Trend' : 'Số lượng bài báo theo năm'),
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: useLineChart ? _buildLineChart() : _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (trends.map((e) => e.count).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: trends.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.count.toDouble(),
                color: AppColors.accent,
                width: trends.length > 50 ? 2 : (trends.length > 20 ? 4 : 12),
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
              final year = trends[group.x.toInt()].year;
              return BarTooltipItem(
                '$year: ${rod.toY.toInt()} bài',
                AppTextStyles.labelCaps.copyWith(color: AppColors.textInverted),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        maxY: (trends.map((e) => e.count).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
        gridData: const FlGridData(show: false),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: trends.asMap().entries.map((e) {
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
                final year = trends[spot.x.toInt()].year;
                return LineTooltipItem(
                  '$year: ${spot.y.toInt()} bài',
                  AppTextStyles.labelCaps.copyWith(color: AppColors.textInverted),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            int index = value.toInt();
            if (index >= 0 && index < trends.length) {
              int showEvery = 1;
              if (trends.length > 40) {
                showEvery = 10;
              } else if (trends.length > 20) {
                showEvery = 5;
              }

              if (index % showEvery == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    trends[index].year.toString(),
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
