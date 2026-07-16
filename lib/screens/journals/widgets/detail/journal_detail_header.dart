import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class JournalDetailHeader extends StatelessWidget {
  final Journal? journal;
  final String fallbackName;
  final bool isFavorite;
  final ValueChanged<Journal> onToggleFavorite;
  final ValueChanged<String?> onOpenLink;

  const JournalDetailHeader({
    super.key,
    required this.journal,
    required this.fallbackName,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    final sourceType = journal?.type?.trim().isNotEmpty == true
        ? journal!.type!.toUpperCase()
        : 'JOURNAL';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primarySoft, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeaderBadge(label: sourceType, icon: Icons.book_outlined),
              if (journal?.isOa == true)
                const _HeaderBadge(label: 'OPEN ACCESS', icon: Icons.lock_open),
              if (journal?.isInDoaj == true)
                const _HeaderBadge(
                  label: 'DOAJ',
                  icon: Icons.verified_outlined,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            journal?.name ?? fallbackName,
            style: AppTextStyles.h1.copyWith(
              color: AppColors.surface,
              fontSize: 26,
              height: 1.15,
            ),
          ),
          if (journal?.publisher?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              journal!.publisher!,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.surface.withValues(alpha: 0.86),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: journal == null
                    ? null
                    : () => onToggleFavorite(journal!),
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                label: Text(isFavorite ? 'Saved' : 'Save Journal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.surface,
                  side: BorderSide(
                    color: AppColors.surface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              if (journal?.homepageUrl?.isNotEmpty == true)
                OutlinedButton.icon(
                  onPressed: () => onOpenLink(journal!.homepageUrl),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Homepage'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.surface,
                    side: BorderSide(
                      color: AppColors.surface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeaderBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.surface),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.surface.withValues(alpha: 0.9),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
