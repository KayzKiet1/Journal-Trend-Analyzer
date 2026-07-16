import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../common/keyword_formatters.dart';
import '../common/keyword_section_card.dart';

class KeywordDetailSummary extends StatelessWidget {
  final int totalPublications;

  const KeywordDetailSummary({super.key, required this.totalPublications});

  @override
  Widget build(BuildContext context) {
    return KeywordSectionCard(
      title: 'Analysis Scope',
      icon: Icons.radar_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${compactCount(totalPublications)} journal articles match this keyword within the selected search.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Source: selected journal article search.',
            style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}
