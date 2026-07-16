import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import 'journal_detail_formatters.dart';
import 'journal_detail_section_card.dart';

class JournalDetailStatsCard extends StatelessWidget {
  final Journal? journal;

  const JournalDetailStatsCard({super.key, required this.journal});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        'Publications',
        compactCount(journal?.worksCount ?? 0),
        Icons.article_outlined,
      ),
      _MetricData(
        'Citations',
        compactCount(journal?.citedByCount ?? 0),
        Icons.format_quote,
      ),
      _MetricData('H-index', journal?.hIndex?.toString() ?? '-', Icons.tag),
      _MetricData(
        'I10-index',
        journal?.i10Index?.toString() ?? '-',
        Icons.format_list_numbered,
      ),
      _MetricData(
        '2yr citedness',
        journal?.twoYearMeanCitedness?.toStringAsFixed(3) ?? '-',
        Icons.trending_up,
      ),
    ];

    return JournalDetailSectionCard(
      title: 'Key Metrics',
      icon: Icons.analytics_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 420;
              return GridView.count(
                crossAxisCount: isWide ? 3 : 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 1.45 : 1.35,
                children: metrics
                    .map((metric) => _MetricTile(metric: metric))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'H-index and I10-index are calculated for this source from OpenAlex works. 2yr citedness is a source-level citation average.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _MetricData metric;

  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(metric.icon, color: AppColors.accent, size: 20),
          Text(
            metric.value,
            style: AppTextStyles.h2.copyWith(color: AppColors.accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            metric.label,
            style: AppTextStyles.labelCaps,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;

  const _MetricData(this.label, this.value, this.icon);
}
