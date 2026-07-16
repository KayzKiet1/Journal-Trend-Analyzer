import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/publication_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../viewmodels/publication_bookmark_view_model.dart';
import '../../../../widgets/publication_card.dart';

class AuthorPublicationsList extends StatelessWidget {
  final ScrollController scrollController;
  final List<Publication> publications;
  final bool hasMore;
  final ValueChanged<Publication> onPublicationTap;

  const AuthorPublicationsList({
    super.key,
    required this.scrollController,
    required this.publications,
    required this.hasMore,
    required this.onPublicationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: publications.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == publications.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            final publication = publications[index];
            return Consumer<PublicationBookmarkViewModel>(
              builder: (context, bookmarks, _) => PublicationCard(
                title: publication.title,
                authors: publication.authorsString,
                journal: publication.journalName,
                year: publication.publicationYear.toString(),
                citations: publication.citedByCount,
                isBookmarked: bookmarks.isBookmarked(publication.id),
                onBookmarkToggle: () => bookmarks.toggleBookmark(publication),
                onTap: () => onPublicationTap(publication),
              ),
            );
          },
        ),
      ),
    );
  }
}
