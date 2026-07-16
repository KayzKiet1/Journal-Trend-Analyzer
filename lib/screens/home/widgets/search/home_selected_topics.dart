import 'package:flutter/material.dart';

import '../../../../models/research_topic_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class HomeSelectedTopics extends StatelessWidget {
  final List<ResearchTopic> selectedTopics;
  final ValueChanged<ResearchTopic> onToggleTopic;

  const HomeSelectedTopics({
    super.key,
    required this.selectedTopics,
    required this.onToggleTopic,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedTopics.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE FILTERS',
            style: AppTextStyles.labelCaps.copyWith(color: AppColors.success),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: selectedTopics
                .map(
                  (topic) => _SelectedTopicChip(
                    topic: topic,
                    onDeleted: () => onToggleTopic(topic),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SelectedTopicChip extends StatelessWidget {
  final ResearchTopic topic;
  final VoidCallback onDeleted;

  const _SelectedTopicChip({required this.topic, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(topic.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: AppColors.accentLight,
      deleteIconColor: AppColors.accent,
      labelStyle: AppTextStyles.labelCaps.copyWith(
        color: AppColors.primary,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.accent, width: 1.0),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );
  }
}
