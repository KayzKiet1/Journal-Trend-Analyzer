import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class RemoteConfigPanel extends StatelessWidget {
  final int maxJournalsDisplay;
  final int maxKeywordsDisplay;
  final bool enableReportExport;
  final String status;
  final String? error;
  final bool isLoading;
  final VoidCallback onFetch;

  const RemoteConfigPanel({
    super.key,
    required this.maxJournalsDisplay,
    required this.maxKeywordsDisplay,
    required this.enableReportExport,
    required this.status,
    required this.error,
    required this.isLoading,
    required this.onFetch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_outlined, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Firebase Remote Config', style: AppTextStyles.h2),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fetch live feature settings from Firebase Console. Change these values in Remote Config, then tap fetch to update the app without rebuilding.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _ConfigRow(
                  title: 'Journal cards limit',
                  value: maxJournalsDisplay.toString(),
                  icon: Icons.book_outlined,
                ),
                _ConfigRow(
                  title: 'Keyword rows limit',
                  value: maxKeywordsDisplay.toString(),
                  icon: Icons.analytics_outlined,
                ),
                _ConfigRow(
                  title: 'PDF export feature',
                  value: enableReportExport ? 'Enabled' : 'Disabled',
                  icon: Icons.picture_as_pdf_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Status: $status',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('fetch_remote_config_button'),
              onPressed: isLoading ? null : onFetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textInverted,
                disabledBackgroundColor: AppColors.accent.withValues(
                  alpha: 0.65,
                ),
                disabledForegroundColor: AppColors.textInverted,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textInverted,
                      ),
                    )
                  : const Icon(Icons.cloud_download_outlined),
              label: Text(isLoading ? 'FETCHING CONFIG...' : 'FETCH CONFIG'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ConfigRow({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title, style: AppTextStyles.bodySmall)),
          Text(
            value,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
