import 'package:flutter/material.dart';

import '../../../../widgets/feature_hero_card.dart';

class KeywordHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<String> badges;

  const KeywordHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return FeatureHeroCard(
      eyebrow: eyebrow,
      title: title,
      description: subtitle,
      icon: Icons.sell_outlined,
      badges: badges,
    );
  }
}
