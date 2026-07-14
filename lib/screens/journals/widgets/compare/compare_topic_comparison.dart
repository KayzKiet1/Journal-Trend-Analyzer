import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class CompareTopicComparison extends StatelessWidget {
  final List<Journal> journals;
  final Map<String, List<Map<String, dynamic>>> topicsByJournal;

  const CompareTopicComparison({
    super.key,
    required this.journals,
    required this.topicsByJournal,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = journals.map((journal) {
          final topics = topicsByJournal[journal.id] ?? [];
          return _TopicCard(journalName: journal.name, topics: topics);
        }).toList();

        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: AppSpacing.md),
              cards[1],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String journalName;
  final List<Map<String, dynamic>> topics;

  const _TopicCard({required this.journalName, required this.topics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(journalName, style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.md),
          if (topics.isEmpty)
            Text('Không có dữ liệu topic.', style: AppTextStyles.bodySmall)
          else
            ...topics.map(
              (topic) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic['name'].toString(),
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${topic['count'] ?? 0}',
                      style: AppTextStyles.labelCaps.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
