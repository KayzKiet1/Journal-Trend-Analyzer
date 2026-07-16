import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/trend_data_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

class TopicEvolutionChart extends StatelessWidget {
  final Map<String, List<TrendData>> data;

  const TopicEvolutionChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('No topic evolution data available')),
      );
    }

    // Lấy tất cả các năm để làm trục X
    Set<int> allYears = {};
    for (var list in data.values) {
      for (var trend in list) {
        allYears.add(trend.year);
      }
    }
    List<int> sortedYears = allYears.toList()..sort();
    if (sortedYears.isEmpty) return const SizedBox.shrink();

    // Giới hạn hiển thị 15 năm gần nhất để biểu đồ không quá dày
    if (sortedYears.length > 15) {
      sortedYears = sortedYears.sublist(sortedYears.length - 15);
    }

    final colors = [
      AppColors.accent,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return Container(
      height: 350,
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
          Text('Topic Evolution', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.sm),
          _buildLegend(colors),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 &&
                            index < sortedYears.length &&
                            index % 3 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              sortedYears[index].toString(),
                              style: AppTextStyles.labelCaps.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: data.entries.toList().asMap().entries.map((
                  entry,
                ) {
                  int idx = entry.key;
                  List<TrendData> trends = entry.value.value;

                  return LineChartBarData(
                    spots: sortedYears.asMap().entries.map((yearEntry) {
                      int yearIdx = yearEntry.key;
                      int year = yearEntry.value;
                      final trend = trends.firstWhere(
                        (t) => t.year == year,
                        orElse: () => TrendData(year: year, count: 0),
                      );
                      return FlSpot(yearIdx.toDouble(), trend.count.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: colors[idx % colors.length],
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors[idx % colors.length].withValues(alpha: 0.1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(List<Color> colors) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: data.keys.toList().asMap().entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              color: colors[entry.key % colors.length],
            ),
            const SizedBox(width: 4),
            Text(
              entry.value,
              style: AppTextStyles.labelCaps.copyWith(fontSize: 9),
            ),
          ],
        );
      }).toList(),
    );
  }
}
