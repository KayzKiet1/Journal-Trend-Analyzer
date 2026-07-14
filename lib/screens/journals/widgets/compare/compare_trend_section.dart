import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../models/trend_data_model.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../../widgets/year_trend_chart.dart';

class CompareTrendSection extends StatelessWidget {
  final String title;
  final List<Journal> journals;
  final List<TrendData> Function(Journal journal) trendsBuilder;

  const CompareTrendSection({
    super.key,
    required this.title,
    required this.journals,
    required this.trendsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final charts = journals.map((journal) {
              return YearTrendChart(
                trends: trendsBuilder(journal),
                forceLineChart: true,
                title: journal.name,
              );
            }).toList();

            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  charts[0],
                  const SizedBox(height: AppSpacing.md),
                  charts[1],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: charts[0]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: charts[1]),
              ],
            );
          },
        ),
      ],
    );
  }
}
