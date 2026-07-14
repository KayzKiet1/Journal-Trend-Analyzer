import 'package:flutter/material.dart';

import '../../../../models/publication_model.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import 'publication_authors_row.dart';
import 'publication_doi_row.dart';
import 'publication_info_row.dart';

class PublicationDetailContent extends StatelessWidget {
  final Publication publication;
  final void Function(String authorId, String authorName) onAuthorTap;
  final ValueChanged<String?> onOpenDoi;

  const PublicationDetailContent({
    super.key,
    required this.publication,
    required this.onAuthorTap,
    required this.onOpenDoi,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        key: const Key('publication_detail_content'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(publication.title, style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.xl),
          PublicationAuthorsRow(
            publication: publication,
            onAuthorTap: onAuthorTap,
          ),
          PublicationInfoRow(
            icon: Icons.calendar_today,
            label: 'Publication year',
            value: publication.publicationYear.toString(),
          ),
          PublicationInfoRow(
            icon: Icons.book,
            label: 'Journal',
            value: publication.journalName,
          ),
          PublicationInfoRow(
            icon: Icons.format_quote,
            label: 'Citations',
            value: publication.citedByCount.toString(),
          ),
          PublicationDoiRow(doi: publication.doi, onOpenDoi: onOpenDoi),
          const SizedBox(height: AppSpacing.xl * 2),
          Text('ABSTRACT', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.md),
          Text(
            publication.abstractText,
            style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
          ),
          const SizedBox(height: AppSpacing.xl * 2),
        ],
      ),
    );
  }
}
