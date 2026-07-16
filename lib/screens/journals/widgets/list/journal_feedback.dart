import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class JournalSearchError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const JournalSearchError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JournalEmptyState extends StatelessWidget {
  final bool hasQuery;
  final VoidCallback onClear;

  const JournalEmptyState({
    super.key,
    required this.hasQuery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 40,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No journals found', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasQuery
                ? 'Try a broader source name or clear your search.'
                : 'OpenAlex did not return journal sources yet.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (hasQuery) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }
}
