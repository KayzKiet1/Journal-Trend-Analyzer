import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/research_topic_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../../viewmodels/publication_view_model.dart';
import '../../../../widgets/app_text_field.dart';
import '../home_formatters.dart';

class HomeTopicSuggestions extends StatelessWidget {
  final TextEditingController searchController;
  final List<ResearchTopic> selectedTopics;
  final bool isLoadingSuggestions;
  final ValueChanged<String> onSearchTopic;
  final VoidCallback onClearSelectedTopics;
  final ValueChanged<ResearchTopic> onToggleTopic;

  const HomeTopicSuggestions({
    super.key,
    required this.searchController,
    required this.selectedTopics,
    required this.isLoadingSuggestions,
    required this.onSearchTopic,
    required this.onClearSelectedTopics,
    required this.onToggleTopic,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        key: const Key('topic_filter_toggle'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => _openTopicFilter(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.tune, color: AppColors.accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Topic filters', style: AppTextStyles.bodyLarge),
                    if (_summaryText != null)
                      Text(_summaryText!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (isLoadingSuggestions)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.secondary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? get _summaryText {
    if (selectedTopics.isEmpty) return null;
    if (selectedTopics.length == 1) return selectedTopics.first.name;
    return '${selectedTopics.length} selected';
  }

  void _openTopicFilter(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusMd),
        ),
      ),
      builder: (context) => _TopicFilterSheet(
        initialQuery: searchController.text,
        onSearchTopic: onSearchTopic,
        onToggleTopic: onToggleTopic,
        onClearSelectedTopics: onClearSelectedTopics,
      ),
    );
  }
}

class _TopicFilterSheet extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String> onSearchTopic;
  final ValueChanged<ResearchTopic> onToggleTopic;
  final VoidCallback onClearSelectedTopics;

  const _TopicFilterSheet({
    required this.initialQuery,
    required this.onSearchTopic,
    required this.onToggleTopic,
    required this.onClearSelectedTopics,
  });

  @override
  State<_TopicFilterSheet> createState() => _TopicFilterSheetState();
}

class _TopicFilterSheetState extends State<_TopicFilterSheet> {
  late final TextEditingController _topicController;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.initialQuery.trim());
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _searchTopics() {
    final query = _topicController.text.trim();
    if (query.length < 2) return;
    widget.onSearchTopic(query);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Consumer<PublicationViewModel>(
              builder: (context, controller, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Refine by topic',
                            style: AppTextStyles.h2,
                          ),
                        ),
                        IconButton(
                          onPressed: Navigator.of(context).pop,
                          icon: const Icon(Icons.close),
                          color: AppColors.secondary,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            fieldKey: const Key('topic_filter_search_field'),
                            controller: _topicController,
                            hintText: 'Search topic filter...',
                            prefixIcon: Icons.search,
                            onSubmitted: _searchTopics,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            key: const Key('topic_filter_search_button'),
                            onPressed: controller.isLoadingTopicSuggestions
                                ? null
                                : _searchTopics,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.textInverted,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                            child: controller.isLoadingTopicSuggestions
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textInverted,
                                    ),
                                  )
                                : const Icon(Icons.search, size: 20),
                          ),
                        ),
                      ],
                    ),
                    if (controller.selectedTopics.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${controller.selectedTopics.length} selected',
                              style: AppTextStyles.labelCaps.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onClearSelectedTopics,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Flexible(
                      child: _TopicFilterResults(
                        topicSuggestions: controller.topicSuggestions,
                        selectedTopics: controller.selectedTopics,
                        isLoadingSuggestions:
                            controller.isLoadingTopicSuggestions,
                        suggestionError: controller.topicSuggestionError,
                        onToggleTopic: widget.onToggleTopic,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicFilterResults extends StatelessWidget {
  final List<ResearchTopic> topicSuggestions;
  final List<ResearchTopic> selectedTopics;
  final bool isLoadingSuggestions;
  final String suggestionError;
  final ValueChanged<ResearchTopic> onToggleTopic;

  const _TopicFilterResults({
    required this.topicSuggestions,
    required this.selectedTopics,
    required this.isLoadingSuggestions,
    required this.suggestionError,
    required this.onToggleTopic,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingSuggestions) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (suggestionError.isNotEmpty && topicSuggestions.isEmpty) {
      return _TopicFilterMessage(
        message: suggestionError,
        color: AppColors.error,
      );
    }

    if (topicSuggestions.isEmpty) {
      return const _TopicFilterMessage(
        message: 'Enter a topic and tap search.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: topicSuggestions.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final topic = topicSuggestions[index];
        return _TopicOption(
          topic: topic,
          selected: selectedTopics.any((item) => item.id == topic.id),
          onTap: () => onToggleTopic(topic),
        );
      },
    );
  }
}

class _TopicFilterMessage extends StatelessWidget {
  final String message;
  final Color? color;

  const _TopicFilterMessage({required this.message, this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(
          color: color ?? AppColors.secondary,
        ),
      ),
    );
  }
}

class _TopicOption extends StatelessWidget {
  final ResearchTopic topic;
  final bool selected;
  final VoidCallback onTap;

  const _TopicOption({
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentLight : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.border,
          width: 1,
        ),
      ),
      child: InkWell(
        key: Key('topic_option_${topic.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected
                    ? AppColors.accent
                    : AppColors.secondary.withValues(alpha: 0.75),
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  topic.name,
                  style: AppTextStyles.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (topic.worksCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  compactCount(topic.worksCount),
                  style: AppTextStyles.labelCaps.copyWith(
                    color: selected ? AppColors.accent : AppColors.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
