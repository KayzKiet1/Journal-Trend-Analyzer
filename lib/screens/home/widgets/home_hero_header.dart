import 'package:flutter/material.dart';

import '../../../widgets/feature_hero_card.dart';

class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureHeroCard(
      eyebrow: 'OPENALEX WORK DISCOVERY',
      title: 'Explore Academic Insights',
      description:
          'Search journal articles by keyword and review publication trends, influential papers, authors, and journals.',
      icon: Icons.auto_graph,
    );
  }
}
