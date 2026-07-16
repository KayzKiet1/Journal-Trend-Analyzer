import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class KeywordFixtureDetailScreen extends StatelessWidget {
  final String keywordName;
  final String topicLabel;

  const KeywordFixtureDetailScreen({
    super.key,
    required this.keywordName,
    required this.topicLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Keyword Analysis')),
      body: SingleChildScrollView(
        key: const Key('keyword_detail_content'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(keywordName, style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.md),
            Text(topicLabel, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            Text('Keyword Role', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sample keyword view showing where this keyword fits inside the selected research topic.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Articles to Open', style: AppTextStyles.h2),
          ],
        ),
      ),
    );
  }
}
