import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class JournalLibraryPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (favorites.isEmpty && recentViewed.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (favorites.isNotEmpty) ...[
          _JournalStrip(
            title: 'FAVORITE JOURNALS',
            journals: favorites,
            icon: Icons.star,
            onOpenJournal: onOpenJournal,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (recentViewed.isNotEmpty) ...[
          _JournalStrip(
            title: 'RECENTLY VIEWED',
            journals: recentViewed,
            icon: Icons.history,
            onOpenJournal: onOpenJournal,
            trailing: TextButton(
              onPressed: onClearRecentViewed,
              child: const Text('Clear'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
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
