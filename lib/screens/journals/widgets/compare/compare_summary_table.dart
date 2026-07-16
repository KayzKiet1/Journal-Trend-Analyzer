import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class CompareSummaryTable extends StatelessWidget {
  final Journal left;
  final Journal right;
  final int currentYear;
  final bool excludeFutureYears;
  final int Function(Journal journal) worksCountForCompare;
  final int Function(Journal journal) citationsForCompare;
  final String Function(Journal journal) avgCitations;

  const CompareSummaryTable({
    super.key,
    required this.left,
    required this.right,
    required this.currentYear,
    required this.excludeFutureYears,
    required this.worksCountForCompare,
    required this.citationsForCompare,
    required this.avgCitations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary, width: 1),
      ),
      child: Column(
        children: [
          _MetricRow('Journal', left.name, right.name, isHeader: true),
          _MetricRow(
            'Publisher',
            left.publisher ?? '-',
            right.publisher ?? '-',
          ),
          _MetricRow(
            excludeFutureYears
                ? 'Publications (<= $currentYear)'
                : 'Publications',
            '${worksCountForCompare(left)}',
            '${worksCountForCompare(right)}',
          ),
          _MetricRow(
            excludeFutureYears ? 'Citations (<= $currentYear)' : 'Citations',
            '${citationsForCompare(left)}',
            '${citationsForCompare(right)}',
          ),
          _MetricRow(
            'Avg citations/publication',
            avgCitations(left),
            avgCitations(right),
          ),
          _MetricRow(
            'H-index',
            left.hIndex?.toString() ?? '-',
            right.hIndex?.toString() ?? '-',
          ),
          _MetricRow(
            'I10-index',
            left.i10Index?.toString() ?? '-',
            right.i10Index?.toString() ?? '-',
          ),
          _MetricRow(
            '2yr mean citedness',
            left.twoYearMeanCitedness?.toStringAsFixed(3) ?? '-',
            right.twoYearMeanCitedness?.toStringAsFixed(3) ?? '-',
          ),
          _MetricRow(
            'Open access',
            left.isOa ? 'Yes' : 'No',
            right.isOa ? 'Yes' : 'No',
          ),
          _MetricRow(
            'In DOAJ',
            left.isInDoaj ? 'Yes' : 'No',
            right.isInDoaj ? 'Yes' : 'No',
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String left;
  final String right;
  final bool isHeader;

  const _MetricRow(this.label, this.left, this.right, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    final textStyle = isHeader
        ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)
        : AppTextStyles.bodySmall;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.secondary.withValues(alpha: 0.18),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
            ),
          ),
          Expanded(flex: 4, child: Text(left, style: textStyle)),
          const SizedBox(width: AppSpacing.md),
          Expanded(flex: 4, child: Text(right, style: textStyle)),
        ],
      ),
    );
  }
}
