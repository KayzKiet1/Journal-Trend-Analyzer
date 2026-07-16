import 'package:flutter/material.dart';

import '../../../../models/recent_search_model.dart';
import '../../../../models/research_topic_model.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../widgets/app_text_field.dart';
import '../recent/home_recent_searches.dart';
import 'home_search_button.dart';
import 'home_search_hint.dart';
import 'home_selected_topics.dart';
import 'home_topic_suggestions.dart';

class HomeSearchSection extends StatelessWidget {
  final TextEditingController searchController;
  final List<RecentSearch> recentSearches;
  final List<ResearchTopic> selectedTopics;
  final bool isLoadingDashboard;
  final bool isLoadingSuggestions;
  final VoidCallback onSearch;
  final ValueChanged<String> onSearchTopic;
  final ValueChanged<String> onSearchTextChanged;
  final ValueChanged<RecentSearch> onRecentSearchTap;
  final ValueChanged<ResearchTopic> onToggleTopic;
  final VoidCallback onClearSelectedTopics;
  final VoidCallback onClearSearchInput;

  const HomeSearchSection({
    super.key,
    required this.searchController,
    required this.recentSearches,
    required this.selectedTopics,
    required this.isLoadingDashboard,
    required this.isLoadingSuggestions,
    required this.onSearch,
    required this.onSearchTopic,
    required this.onSearchTextChanged,
    required this.onRecentSearchTap,
    required this.onToggleTopic,
    required this.onClearSelectedTopics,
    required this.onClearSearchInput,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          fieldKey: const Key('home_topic_search_field'),
          controller: searchController,
          hintText: 'Enter a research topic...',
          prefixIcon: Icons.search,
          suffixIcon: searchController.text.isEmpty ? null : Icons.close,
          onSuffixTap: onClearSearchInput,
          onChanged: onSearchTextChanged,
          onSubmitted: onSearch,
        ),
        const SizedBox(height: AppSpacing.md),
        HomeTopicSuggestions(
          searchController: searchController,
          selectedTopics: selectedTopics,
          isLoadingSuggestions: isLoadingSuggestions,
          onSearchTopic: onSearchTopic,
          onClearSelectedTopics: onClearSelectedTopics,
          onToggleTopic: onToggleTopic,
        ),
        HomeSelectedTopics(
          selectedTopics: selectedTopics,
          onToggleTopic: onToggleTopic,
        ),
        const SizedBox(height: AppSpacing.md),
        HomeSearchButton(
          searchController: searchController,
          selectedTopicCount: selectedTopics.length,
          isLoadingDashboard: isLoadingDashboard,
          onSearch: onSearch,
        ),
        HomeSearchHint(
          searchController: searchController,
          hasSelectedTopics: selectedTopics.isNotEmpty,
        ),
        if (recentSearches.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          HomeRecentSearches(
            history: recentSearches,
            onRecentSearchTap: onRecentSearchTap,
          ),
        ],
      ],
    );
  }
}
