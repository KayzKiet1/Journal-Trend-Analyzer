import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class JournalCard extends StatelessWidget {
  final Journal journal;
  final bool isSelectedForCompare;
  final bool isFavorite;
  final VoidCallback onCompareToggle;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const JournalCard({
    super.key,
    required this.journal,
    required this.isSelectedForCompare,
    required this.isFavorite,
    required this.onCompareToggle,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final leading = Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelectedForCompare
                ? AppColors.accent
                : AppColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.book_outlined,
            color: isSelectedForCompare ? AppColors.surface : AppColors.accent,
            size: 24,
          ),
        );
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              journal.name,
              style: AppTextStyles.h2.copyWith(fontSize: isCompact ? 16 : 18),
              maxLines: isCompact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              journal.publisher ?? 'OpenAlex journal source',
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _MetricBadge(
                  icon: Icons.article_outlined,
                  label: '${_compactCount(journal.worksCount)} publications',
                ),
                _MetricBadge(
                  icon: Icons.format_quote,
                  label: '${_compactCount(journal.citedByCount)} citations',
                ),
              ],
            ),
          ],
        );
        final actionButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: isFavorite ? 'Remove from library' : 'Save journal',
              child: IconButton(
                onPressed: onFavoriteToggle,
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? AppColors.accent : AppColors.secondary,
                ),
              ),
            ),
            Tooltip(
              message: isSelectedForCompare
                  ? 'Remove from comparison'
                  : 'Select for comparison',
              child: IconButton(
                onPressed: onCompareToggle,
                icon: Icon(
                  isSelectedForCompare ? Icons.check_box : Icons.compare_arrows,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        );
        final openHint = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Details',
                style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: AppColors.secondary,
              ),
            ],
          ),
        );
        final actions = isCompact
            ? Row(children: [actionButtons, const Spacer(), openHint])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  actionButtons,
                  const SizedBox(height: AppSpacing.sm),
                  openHint,
                ],
              );
        final cardContent = isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leading,
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: content),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  actions,
                ],
              )
            : Row(
                children: [
                  leading,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: content),
                  const SizedBox(width: AppSpacing.sm),
                  actions,
                ],
              );

        return Material(
          key: Key('journal_card_${journal.id}'),
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelectedForCompare
                    ? AppColors.accentLight
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelectedForCompare
                      ? AppColors.accent
                      : AppColors.border,
                  width: AppSpacing.borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: cardContent,
            ),
          ),
        );
      },
    );
  }

  String _compactCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.accent,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
