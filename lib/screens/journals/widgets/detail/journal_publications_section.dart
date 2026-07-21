import 'package:flutter/material.dart';

import '../../../../models/publication_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../../viewmodels/journal_detail_view_model.dart';
import '../../../../widgets/publication_card.dart';
import 'journal_detail_formatters.dart';

class JournalPublicationsSection extends StatelessWidget {
  final List<Publication> publications;
  final int totalCount;
  final JournalPublicationSort selectedSort;
  final bool isLoading;
  final String errorMessage;
  final ValueChanged<JournalPublicationSort> onSortChanged;
  final ValueChanged<Publication> onPublicationTap;
  final bool Function(String publicationId) isPublicationBookmarked;
  final ValueChanged<Publication> onBookmarkToggle;

  const JournalPublicationsSection({
    super.key,
    required this.publications,
    required this.totalCount,
    required this.selectedSort,
    required this.isLoading,
    required this.errorMessage,
    required this.onSortChanged,
    required this.onPublicationTap,
    required this.isPublicationBookmarked,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.article_outlined, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Journal publications', style: AppTextStyles.h2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    totalCount > 0
                        ? '${compactCount(totalCount)} works from this journal'
                        : 'Works from this journal',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<JournalPublicationSort>(
          segments: JournalPublicationSort.values
              .map(
                (sort) => ButtonSegment(
                  value: sort,
                  icon: Icon(
                    sort == JournalPublicationSort.newest
                        ? Icons.update
                        : Icons.format_quote,
                    size: 16,
                  ),
                  label: Text(sort.label),
                ),
              )
              .toList(),
          selected: {selectedSort},
          onSelectionChanged: isLoading
              ? null
              : (selection) => onSortChanged(selection.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(AppTextStyles.labelCaps),
            foregroundColor: const WidgetStatePropertyAll(
              AppColors.textPrimary,
            ),
          ),
        ),
        if (isLoading) ...[
          const SizedBox(height: AppSpacing.md),
          const LinearProgressIndicator(minHeight: 3),
        ],
        if (errorMessage.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            errorMessage,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (!isLoading && publications.isEmpty && errorMessage.isEmpty)
          Text(
            'No publications found for this journal.',
            style: AppTextStyles.bodySmall,
          )
        else
          ...publications.map(
            (publication) => PublicationCard(
              title: publication.title,
              year: publication.publicationYear.toString(),
              journal: publication.journalName,
              authors: publication.authorsString,
              citations: publication.citedByCount,
              isBookmarked: isPublicationBookmarked(publication.id),
              onBookmarkToggle: () => onBookmarkToggle(publication),
              onTap: () => onPublicationTap(publication),
              showJournal: false,
            ),
          ),
      ],
    );
  }
}
