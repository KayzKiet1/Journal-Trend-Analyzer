import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class JournalLibraryPanel extends StatefulWidget {
  final List<Journal> favorites;
  final List<Journal> recentViewed;
  final VoidCallback onClearRecentViewed;
  final ValueChanged<Journal> onOpenJournal;

  const JournalLibraryPanel({
    super.key,
    required this.favorites,
    required this.recentViewed,
    required this.onClearRecentViewed,
    required this.onOpenJournal,
  });

  @override
  State<JournalLibraryPanel> createState() => _JournalLibraryPanelState();
}

class _JournalLibraryPanelState extends State<JournalLibraryPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.favorites.isEmpty && widget.recentViewed.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalItems = widget.favorites.length + widget.recentViewed.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(
                      Icons.collections_bookmark_outlined,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saved journal shelf', style: AppTextStyles.h2),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${widget.favorites.length} favorites • ${widget.recentViewed.length} recent',
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      totalItems.toString(),
                      style: AppTextStyles.h2.copyWith(color: AppColors.accent),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.favorites.isNotEmpty) ...[
                    _JournalStrip(
                      title: 'FAVORITE JOURNALS',
                      journals: widget.favorites,
                      icon: Icons.star,
                      onOpenJournal: widget.onOpenJournal,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (widget.recentViewed.isNotEmpty)
                    _JournalStrip(
                      title: 'RECENTLY VIEWED',
                      journals: widget.recentViewed,
                      icon: Icons.history,
                      onOpenJournal: widget.onOpenJournal,
                      trailing: TextButton(
                        onPressed: widget.onClearRecentViewed,
                        child: const Text('Clear'),
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _JournalStrip extends StatelessWidget {
  final String title;
  final List<Journal> journals;
  final IconData icon;
  final ValueChanged<Journal> onOpenJournal;
  final Widget? trailing;

  const _JournalStrip({
    required this.title,
    required this.journals,
    required this.icon,
    required this.onOpenJournal,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title, style: AppTextStyles.labelCaps)),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: journals.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _SavedJournalCard(
                journal: journals[index],
                onTap: () => onOpenJournal(journals[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SavedJournalCard extends StatelessWidget {
  final Journal journal;
  final VoidCallback onTap;

  const _SavedJournalCard({required this.journal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
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
            Text(
              journal.name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '${journal.worksCount} publications • ${journal.citedByCount} citations',
              style: AppTextStyles.labelCaps.copyWith(fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
