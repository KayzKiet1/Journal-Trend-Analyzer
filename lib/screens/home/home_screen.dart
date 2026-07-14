import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/user_view_model.dart';
import '../../viewmodels/publication_view_model.dart';
import '../../viewmodels/home_view_model.dart';
import '../../viewmodels/firebase_view_model.dart';
import '../../models/recent_search_model.dart';
import '../../models/research_topic_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../publications/publication_detail_screen.dart';
import 'widgets/dashboard/home_topic_dashboard.dart';
import 'widgets/home_hero_header.dart';
import 'widgets/search/home_search_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HomeViewModel _viewModel = HomeViewModel();

  void _handleSearch() {
    final controller = context.read<PublicationViewModel>();
    if (controller.isLoadingTopicDashboard) return;

    final query = _searchController.text.trim();
    if (query.length < 2) return;

    final selectedTopics = controller.selectedTopics;
    _viewModel.logSearchTopic(
      keyword: query,
      topicCount: selectedTopics.length,
    );
    controller.updateSearchText(query);
    controller.loadWorkSearchDashboard(query);

    context.read<UserViewModel>().addSearch(query);
  }

  void _onSearchTextChanged(String value) {
    setState(() {});
    final controller = context.read<PublicationViewModel>();
    controller.updateSearchText(value);
  }

  void _loadTopicSuggestions(String value) {
    context.read<PublicationViewModel>().loadTopicSuggestions(value);
  }

  void _toggleTopic(ResearchTopic topic) {
    context.read<PublicationViewModel>().toggleTopicFilter(topic);
  }

  void _clearSearchInput() {
    setState(_searchController.clear);
    final controller = context.read<PublicationViewModel>();
    controller.updateSearchText('');
    controller.clearTopicSelection();
  }

  void _handleRecentTopic(RecentSearch search) {
    setState(() {
      _searchController.text = search.label;
    });
    final controller = context.read<PublicationViewModel>();
    controller.updateSearchText(search.label);
    controller.clearTopicSelection();
    controller.loadWorkSearchDashboard(search.label);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize search text and category from controller when returning to screen
    final controller = context.read<PublicationViewModel>();
    final lastSearch = controller.lastSearchText;

    if (_searchController.text.isEmpty && lastSearch.isNotEmpty) {
      _searchController.text = lastSearch;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Journal Trend Analyzer')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child:
                Consumer3<
                  PublicationViewModel,
                  UserViewModel,
                  FirebaseViewModel
                >(
                  builder:
                      (
                        context,
                        publicationController,
                        userController,
                        firebaseController,
                        _,
                      ) {
                        final maxJournals = firebaseController
                            .remoteConfigValues
                            .maxJournalsDisplay;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const HomeHeroHeader(),
                            const SizedBox(height: AppSpacing.lg),
                            HomeSearchSection(
                              searchController: _searchController,
                              recentSearches: userController.recentSearches,
                              selectedTopics:
                                  publicationController.selectedTopics,
                              isLoadingDashboard:
                                  publicationController.isLoadingTopicDashboard,
                              isLoadingSuggestions: publicationController
                                  .isLoadingTopicSuggestions,
                              onSearch: _handleSearch,
                              onSearchTextChanged: _onSearchTextChanged,
                              onRecentSearchTap: _handleRecentTopic,
                              onSearchTopic: _loadTopicSuggestions,
                              onToggleTopic: _toggleTopic,
                              onClearSelectedTopics:
                                  publicationController.clearSelectedTopics,
                              onClearSearchInput: _clearSearchInput,
                            ),
                            HomeTopicDashboard(
                              isLoading:
                                  publicationController.isLoadingTopicDashboard,
                              error: publicationController.topicDashboardError,
                              totalWorks: publicationController
                                  .topicDashboardTotalWorks,
                              averageCitations: publicationController
                                  .topicDashboardAverageCitations,
                              peakYear:
                                  publicationController.topicDashboardPeakYear,
                              publications: publicationController
                                  .topicDashboardPublications,
                              trends:
                                  publicationController.topicDashboardTrends,
                              topAuthors: publicationController
                                  .topicDashboardTopAuthors,
                              topJournals: publicationController
                                  .topicDashboardTopJournals,
                              maxJournalsDisplay: maxJournals,
                              onPublicationTap: (publication) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PublicationDetailScreen(
                                          publication: publication,
                                        ),
                                  ),
                                );
                              },
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
