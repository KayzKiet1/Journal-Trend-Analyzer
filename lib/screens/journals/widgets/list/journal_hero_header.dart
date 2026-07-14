import 'package:flutter/material.dart';

import '../../../../widgets/feature_hero_card.dart';

class JournalHeroHeader extends StatelessWidget {
  const JournalHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureHeroCard(
      eyebrow: 'OPENALEX JOURNAL SOURCES',
      title: 'Discover Journals',
      description:
          'Search OpenAlex journal sources, review publication scale, and compare selected journals.',
      icon: Icons.library_books_outlined,
    );
  }
}
