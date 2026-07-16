import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class ReportExportPanel extends StatelessWidget {
  final bool isUploading;
  final String? uploadedReportUrl;
  final String currentTopic;
  final int totalPublications;
  final int trendPointCount;
  final int journalCount;
  final int keywordCount;
  final int keywordGrowthCount;
  final bool hasDashboardData;
  final bool isSignedIn;
  final String authEmail;
  final bool exportEnabled;
  final VoidCallback onExport;
  final VoidCallback onCopyUrl;
  final VoidCallback onOpenUrl;

  const ReportExportPanel({
    super.key,
    required this.isUploading,
    required this.uploadedReportUrl,
    required this.currentTopic,
    required this.totalPublications,
    required this.trendPointCount,
    required this.journalCount,
    required this.keywordCount,
    required this.keywordGrowthCount,
    required this.hasDashboardData,
    required this.isSignedIn,
    required this.authEmail,
    required this.exportEnabled,
    required this.onExport,
    required this.onCopyUrl,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final canExport =
        hasDashboardData && isSignedIn && exportEnabled && !isUploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportScope(
          currentTopic: currentTopic,
          totalPublications: totalPublications,
          trendPointCount: trendPointCount,
          journalCount: journalCount,
          keywordCount: keywordCount,
          keywordGrowthCount: keywordGrowthCount,
        ),
        const SizedBox(height: AppSpacing.md),
        _ExportRequirement(
          label: 'Google sign-in',
          isReady: isSignedIn,
          value: isSignedIn ? authEmail : 'Required for Storage',
        ),
        _ExportRequirement(
          label: 'Dashboard data',
          isReady: hasDashboardData,
          value: hasDashboardData
              ? '$totalPublications publications'
              : 'Search and select a topic first',
        ),
        _ExportRequirement(
          label: 'Export flag',
          isReady: exportEnabled,
          value: exportEnabled ? 'Enabled' : 'Disabled',
        ),
        const _ExportRequirement(
          label: 'Export format',
          isReady: true,
          value: 'PDF report',
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('export_pdf_button'),
            onPressed: canExport ? onExport : null,
            icon: isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(
              isUploading
                  ? 'GENERATING AND UPLOADING...'
                  : 'EXPORT PDF & UPLOAD',
            ),
          ),
        ),
        if (uploadedReportUrl != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text('FIREBASE STORAGE URL', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            uploadedReportUrl!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onCopyUrl,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('COPY URL'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenUrl,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('OPEN'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReportScope extends StatelessWidget {
  final String currentTopic;
  final int totalPublications;
  final int trendPointCount;
  final int journalCount;
  final int keywordCount;
  final int keywordGrowthCount;

  const _ReportScope({
    required this.currentTopic,
    required this.totalPublications,
    required this.trendPointCount,
    required this.journalCount,
    required this.keywordCount,
    required this.keywordGrowthCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current export scope', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.xs),
          Text(
            currentTopic.isEmpty
                ? 'No research topic selected yet.'
                : currentTopic,
            style: AppTextStyles.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$totalPublications publications, $trendPointCount yearly trend points, $journalCount journals',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$keywordCount keywords, $keywordGrowthCount growth rows from Keywords tab',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _ExportRequirement extends StatelessWidget {
  final String label;
  final bool isReady;
  final String value;

  const _ExportRequirement({
    required this.label,
    required this.isReady,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isReady ? AppColors.success : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isReady ? Icons.check_circle_outline : Icons.info_outline,
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
