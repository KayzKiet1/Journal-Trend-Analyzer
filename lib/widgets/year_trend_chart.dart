import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/trend_data_model.dart';
import '../utils/app_spacing.dart';

/// Widget hiển thị biểu đồ đường về xu hướng bài báo qua các năm
/// Áp dụng màu chủ đạo Boston Clay (#B8422E) và bo góc 8px chuẩn Heritage
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

    // Màu Boston Clay nhấn cho biểu đồ theo chuẩn Heritage
    const Color bostonClay = Color(0xFFB8422E);

    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0), // Quy chuẩn bo góc 8px trong job.md
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Số lượng bài báo theo năm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < trends.length) {
                          // Chỉ hiển thị cách năm để tránh dày đặc trên màn hình
                          if (index % 2 == 0) {
                            return Text(
                              trends[index].year.toString(),
                              style: const TextStyle(color: Color(0xFF475569), fontSize: 10),
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
                lineBarsData: [
                  LineChartBarData(
                    spots: trends.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: bostonClay,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: bostonClay.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => bostonClay,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final year = trends[spot.x.toInt()].year;
                        return LineTooltipItem(
                          '$year: ${spot.y.toInt()} bài',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
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