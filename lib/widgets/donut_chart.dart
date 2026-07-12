import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

/// Biểu đồ hình bánh Donut hiển thị phân bổ chất lượng (Quartile)
class DonutChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;

  const DonutChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 300,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.secondary, width: 1.0),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: data.map((item) {
                      final color = _hexToColor(item['color'] ?? '#0F766E');
                      final percentage = item['percentage'] ?? 0;
                      return PieChartSectionData(
                        color: color,
                        value: (item['count'] as num).toDouble(),
                        title: '$percentage%',
                        radius: 50,
                        titleStyle: AppTextStyles.labelCaps.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.map((item) {
                    final color = _hexToColor(item['color'] ?? '#0F766E');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['name'],
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }
}
