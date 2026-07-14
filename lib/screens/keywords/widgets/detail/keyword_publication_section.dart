import 'package:flutter/material.dart';

import '../../../../models/publication_model.dart';
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
      title: 'Related Publications',
      icon: Icons.article_outlined,
      child: publications.isEmpty
          ? const KeywordNotice(
              message: 'No related publications found for this search.',
              plain: true,
            )
          : Column(
              children: publications.map((publication) {
                return PublicationCard(
                  title: publication.title,
                  year: publication.publicationYear.toString(),
                  journal: publication.journalName,
                  authors: publication.authorsString,
                  citations: publication.citedByCount,
                  onTap: () => onPublicationTap(publication),
                );
              }).toList(),
            ),
    );
  }
}
