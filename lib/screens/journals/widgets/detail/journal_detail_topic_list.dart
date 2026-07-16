import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import 'journal_detail_formatters.dart';
import 'journal_detail_section_card.dart';

class JournalDetailTopicList extends StatelessWidget {
  final List<Map<String, dynamic>> topics;

  const JournalDetailTopicList({super.key, required this.topics});

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) return const SizedBox.shrink();

    final maxCount = topics
        .map((topic) => (topic['count'] as num?)?.toInt() ?? 0)
        .fold<int>(0, (max, count) => count > max ? count : max);

    return JournalDetailSectionCard(
      title: 'Top Topics',
      icon: Icons.sell_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...topics.map((topic) {
            final count = (topic['count'] as num?)?.toInt() ?? 0;
            final ratio = maxCount == 0 ? 0.0 : count / maxCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic['name']?.toString() ?? 'Unknown topic',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        compactCount(count),
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: ratio.clamp(0.0, 1.0),
                      color: AppColors.accent,
                      backgroundColor: AppColors.accentLight,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: topics.take(4).map((topic) {
              return Chip(
                label: Text(topic['name']?.toString() ?? 'Topic'),
                backgroundColor: AppColors.surfaceTint,
                labelStyle: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                ),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
