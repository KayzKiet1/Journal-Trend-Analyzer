import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

class PublicationCard extends StatelessWidget {
  final String title;
  final String year;
  final String journal;
  final String authors;
  final int citations;
  final VoidCallback onTap;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;

  const PublicationCard({
    super.key,
    required this.title,
    required this.year,
    required this.journal,
    required this.authors,
    required this.citations,
    required this.onTap,
    this.isBookmarked = false,
    this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h2.copyWith(height: 1.25),
                    ),
                  ),
                  if (onBookmarkToggle != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      tooltip: isBookmarked
                          ? 'Remove publication bookmark'
                          : 'Bookmark publication',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: onBookmarkToggle,
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked
                            ? AppColors.accent
                            : AppColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (authors.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  authors,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: _PublicationMetaChip(
                      icon: Icons.menu_book_outlined,
                      label: journal,
                      highlighted: false,
                    ),
                  ),
                  _PublicationMetaChip(
                    icon: Icons.format_quote,
                    label: '$citations',
                    highlighted: true,
                  ),
                  _PublicationMetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: year,
                    highlighted: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicationMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const _PublicationMetaChip({
    required this.icon,
    required this.label,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted ? AppColors.accent : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: highlighted
              ? AppColors.accent.withValues(alpha: 0.18)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelCaps.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
