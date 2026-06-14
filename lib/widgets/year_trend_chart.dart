import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/trend_data_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

/// Widget hiển thị biểu đồ cột (Bar Chart) về xu hướng bài báo qua các năm.
class YearTrendChart extends StatelessWidget {
  final List<TrendData> trends;

  const YearTrendChart({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text("Không có dữ liệu biểu đồ")),
      );
    }

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
            'Số lượng bài báo theo năm',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (trends.map((e) => e.count).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < trends.length) {
                          // Chỉ hiển thị nhãn cách quãng nếu dữ liệu quá nhiều
                          if (trends.length > 8) {
                            if (index % 2 == 0) {
                              return Text(
                                trends[index].year.toString(),
                                style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
                              );
                            }
                          } else {
                            return Text(
                              trends[index].year.toString(),
                              style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
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
                ),
                borderData: FlBorderData(show: false),
                barGroups: trends.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.count.toDouble(),
                        color: AppColors.accent,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
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
            ),
          ),
        ],
      ),
    );
  }
}
