import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../models/publication_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class SavedBookmarksPanel extends StatefulWidget {
  final List<Publication> publications;
  final List<Journal> journals;
  final ValueChanged<Publication> onOpenPublication;
  final ValueChanged<Publication> onRemovePublication;
  final ValueChanged<Journal> onOpenJournal;
  final ValueChanged<Journal> onRemoveJournal;

  const SavedBookmarksPanel({
    super.key,
    required this.publications,
    required this.journals,
    required this.onOpenPublication,
    required this.onRemovePublication,
    required this.onOpenJournal,
    required this.onRemoveJournal,
  });

  @override
  State<SavedBookmarksPanel> createState() => _SavedBookmarksPanelState();
}

class _SavedBookmarksPanelState extends State<SavedBookmarksPanel> {
  @override
  Widget build(BuildContext context) {
    final totalBookmarks = widget.publications.length + widget.journals.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: _openBookmarksSheet,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.bookmarks_outlined, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved bookmarks', style: AppTextStyles.h2),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      totalBookmarks == 0
                          ? 'No saved items yet'
                          : '${widget.publications.length} publications • ${widget.journals.length} journals',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalBookmarks.toString(),
                    style: AppTextStyles.h2.copyWith(color: AppColors.accent),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.secondary.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBookmarksSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusMd),
        ),
      ),
      builder: (sheetContext) {
        return _SavedBookmarksSheet(
          publications: widget.publications,
          journals: widget.journals,
          onOpenPublication: (publication) {
            Navigator.of(sheetContext).pop();
            widget.onOpenPublication(publication);
          },
          onRemovePublication: widget.onRemovePublication,
          onOpenJournal: (journal) {
            Navigator.of(sheetContext).pop();
            widget.onOpenJournal(journal);
          },
          onRemoveJournal: widget.onRemoveJournal,
        );
      },
    );
  }
}

class _SavedBookmarksSheet extends StatefulWidget {
  final List<Publication> publications;
  final List<Journal> journals;
  final ValueChanged<Publication> onOpenPublication;
  final ValueChanged<Publication> onRemovePublication;
  final ValueChanged<Journal> onOpenJournal;
  final ValueChanged<Journal> onRemoveJournal;

  const _SavedBookmarksSheet({
    required this.publications,
    required this.journals,
    required this.onOpenPublication,
    required this.onRemovePublication,
    required this.onOpenJournal,
    required this.onRemoveJournal,
  });

  @override
  State<_SavedBookmarksSheet> createState() => _SavedBookmarksSheetState();
}

class _SavedBookmarksSheetState extends State<_SavedBookmarksSheet> {
  int _selectedIndex = 0;
  late List<Publication> _publications;
  late List<Journal> _journals;

  @override
  void initState() {
    super.initState();
    _publications = List<Publication>.from(widget.publications);
    _journals = List<Journal>.from(widget.journals);
  }

  @override
  Widget build(BuildContext context) {
    final isPublications = _selectedIndex == 0;

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.bookmarks_outlined, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Saved bookmarks', style: AppTextStyles.h2),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment<int>(
                    value: 0,
                    icon: const Icon(Icons.article_outlined),
                    label: Text('Publications (${_publications.length})'),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text('Journals (${_journals.length})'),
                  ),
                ],
                selected: {_selectedIndex},
                onSelectionChanged: (selection) {
                  setState(() => _selectedIndex = selection.first);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (isPublications)
                _PublicationBookmarks(
                  publications: _publications,
                  onOpen: widget.onOpenPublication,
                  onRemove: _removePublication,
                )
              else
                _JournalBookmarks(
                  journals: _journals,
                  onOpen: widget.onOpenJournal,
                  onRemove: _removeJournal,
                ),
            ],
          );
        },
      ),
    );
  }

  void _removePublication(Publication publication) {
    setState(() {
      _publications.removeWhere((item) => item.id == publication.id);
    });
    widget.onRemovePublication(publication);
  }

  void _removeJournal(Journal journal) {
    setState(() {
      _journals.removeWhere((item) => item.id == journal.id);
    });
    widget.onRemoveJournal(journal);
  }
}

class _PublicationBookmarks extends StatelessWidget {
  final List<Publication> publications;
  final ValueChanged<Publication> onOpen;
  final ValueChanged<Publication> onRemove;

  const _PublicationBookmarks({
    required this.publications,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (publications.isEmpty) {
      return const _BookmarkEmptyState(
        icon: Icons.article_outlined,
        message: 'No publication bookmarks yet.',
      );
    }

    return Column(
      children: publications
          .map(
            (publication) => _BookmarkTile(
              icon: Icons.article_outlined,
              title: publication.title,
              subtitle:
                  '${publication.publicationYear} • ${publication.journalName}',
              metric: '${publication.citedByCount} citations',
              onTap: () => onOpen(publication),
              onRemove: () => onRemove(publication),
            ),
          )
          .toList(),
    );
  }
}

class _JournalBookmarks extends StatelessWidget {
  final List<Journal> journals;
  final ValueChanged<Journal> onOpen;
  final ValueChanged<Journal> onRemove;

  const _JournalBookmarks({
    required this.journals,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (journals.isEmpty) {
      return const _BookmarkEmptyState(
        icon: Icons.menu_book_outlined,
        message: 'No journal bookmarks yet.',
      );
    }

    return Column(
      children: journals
          .map(
            (journal) => _BookmarkTile(
              icon: Icons.menu_book_outlined,
              title: journal.name,
              subtitle: journal.publisher ?? 'OpenAlex journal source',
              metric: '${journal.worksCount} works',
              onTap: () => onOpen(journal),
              onRemove: () => onRemove(journal),
            ),
          )
          .toList(),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String metric;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _BookmarkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric,
                      style: AppTextStyles.labelCaps.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove bookmark',
                icon: const Icon(Icons.bookmark_remove_outlined),
                color: AppColors.secondary,
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _BookmarkEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondary),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
