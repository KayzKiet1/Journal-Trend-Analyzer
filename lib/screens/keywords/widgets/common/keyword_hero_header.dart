import 'package:flutter/material.dart';

import '../../../../widgets/feature_hero_card.dart';

class KeywordHeroHeader extends StatelessWidget {
  const KeywordHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureHeroCard(
      eyebrow: 'OPENALEX KEYWORD ANALYSIS',
      title: 'Keyword Trends',
      description:
          'Search a topic directly here to review keyword frequency, momentum, related journals, and matching publications.',
      icon: Icons.sell_outlined,
    );
  }
}
