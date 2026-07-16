import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/publication_model.dart';
import '../../../../viewmodels/publication_bookmark_view_model.dart';
import '../../../../widgets/publication_card.dart';
import '../common/keyword_notice.dart';
import '../common/keyword_section_card.dart';

class KeywordPublicationSection extends StatelessWidget {
  final List<Publication> publications;
  final ValueChanged<Publication> onPublicationTap;

  const KeywordPublicationSection({
    super.key,
    required this.publications,
    required this.onPublicationTap,
  });

  @override
  Widget build(BuildContext context) {
    return KeywordSectionCard(
      title: 'Articles to Open',
      icon: Icons.article_outlined,
      child: publications.isEmpty
          ? const KeywordNotice(
              message: 'No matching articles found for this keyword.',
              plain: true,
            )
          : Consumer<PublicationBookmarkViewModel>(
              builder: (context, bookmarks, _) => Column(
                children: publications.map((publication) {
                  return PublicationCard(
                    title: publication.title,
                    year: publication.publicationYear.toString(),
                    journal: publication.journalName,
                    authors: publication.authorsString,
                    citations: publication.citedByCount,
                    isBookmarked: bookmarks.isBookmarked(publication.id),
                    onBookmarkToggle: () =>
                        bookmarks.toggleBookmark(publication),
                    onTap: () => onPublicationTap(publication),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
