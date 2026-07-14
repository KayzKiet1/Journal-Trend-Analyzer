import 'package:flutter/material.dart';

import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../common/keyword_section_card.dart';

class KeywordChartSection extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const KeywordChartSection({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return KeywordSectionCard(
      title: title,
      icon: Icons.analytics_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
