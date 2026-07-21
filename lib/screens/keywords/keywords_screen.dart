import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recent_search_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../viewmodels/firebase_view_model.dart';
import '../../viewmodels/publication_view_model.dart';
import '../../viewmodels/keywords_view_model.dart';
import '../../viewmodels/user_view_model.dart';
import 'keyword_detail_screen.dart';
import 'widgets/dashboard/keyword_dashboard_content.dart';
import 'widgets/dashboard/keyword_empty_state.dart';
import 'widgets/dashboard/keyword_fixture_dashboard.dart';
import 'widgets/common/keyword_hero_header.dart';
import 'widgets/common/keyword_recent_searches.dart';
import 'widgets/common/keyword_search_panel.dart';
import 'widgets/detail/keyword_fixture_detail_screen.dart';

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<KeywordsViewModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Keyword Trends')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              const KeywordHeroHeader(),
              const SizedBox(height: AppSpacing.lg),
              KeywordSearchPanel(
                controller: _searchController,
                isLoading: viewModel.isLoading,
                resultQuery: viewModel.keywordSearchQuery,
                onSearch: _submitKeywordSearch,
                onClear: _clearKeywordSearch,
                onChanged: (_) => setState(() {}),
              ),
              _buildRecentSearches(),
              const SizedBox(height: AppSpacing.lg),
              _buildTopicKeywordDashboard(context, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicKeywordDashboard(
    BuildContext context,
    KeywordsViewModel viewModel,
  ) {
    final controller = context.watch<PublicationViewModel>();
    final maxKeywords = context
        .watch<FirebaseViewModel>()
        .remoteConfigValues
        .maxKeywordsDisplay;
    final query = viewModel.keywordSearchQuery;
    const topicIds = <String>[];

    if (controller.keywordFixtures.isNotEmpty) {
      return KeywordFixtureDashboard(
        keywords: controller.keywordFixtures,
        topicIds: controller.currentTopicIds,
        scopeLabel: controller.currentWorkScopeLabel,
        onKeywordTap: _openKeywordDetail,
      );
    }

    if (query.isEmpty) {
      return KeywordEmptyState(lastSearchText: viewModel.keywordSearchQuery);
    }

    if (query.length < 2) {
      return const KeywordEmptyState(lastSearchText: '');
    }

    final topicKey = 'keywords:${query.toLowerCase()}';
    if (viewModel.loadedTopicKey != topicKey && !viewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<KeywordsViewModel>().loadKeywordDashboard(
            query: query,
            topicIds: topicIds,
            topicKey: topicKey,
          );
        }
      });
    }

    return KeywordDashboardContent(
      scopeLabel: query,
      topicIds: topicIds,
      topicKey: topicKey,
      topKeywords: viewModel.topKeywords,
      keywordGrowth: viewModel.keywordGrowth,
      keywordTrends: viewModel.keywordTrends,
      maxKeywordsDisplay: maxKeywords,
      isLoading: viewModel.isLoading,
      error: viewModel.errorMessage,
      onRetry: () => viewModel.loadKeywordDashboard(
        query: query,
        topicIds: topicIds,
        topicKey: topicKey,
      ),
      onKeywordTap: _openKeywordDetail,
    );
  }

  void _openKeywordDetail(Map<String, dynamic> keyword) {
    final controller = context.read<PublicationViewModel>();
    final keywordSearchQuery = context
        .read<KeywordsViewModel>()
        .keywordSearchQuery;
    final keywordId = keyword['id']?.toString() ?? '';
    if (keywordId.isEmpty || keywordSearchQuery.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KeywordFixtureDetailScreen(
            keywordName: keyword['name'].toString(),
            topicLabel: controller.currentTopic,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KeywordDetailScreen(
          keywordId: keywordId,
          keywordName: keyword['name'].toString(),
          keywordCount: (keyword['count'] as num?)?.toInt() ?? 0,
          topicIds: const [],
          topicLabel: keywordSearchQuery,
          workQuery: keywordSearchQuery,
        ),
      ),
    );
  }

  void _submitKeywordSearch() {
    final query = _searchController.text.trim();
    if (query.length < 2 || context.read<KeywordsViewModel>().isLoading) {
      return;
    }

    context.read<KeywordsViewModel>().searchKeywords(query);
    context.read<UserViewModel>().addKeywordSearch(query);
    FocusScope.of(context).unfocus();
  }

  void _clearKeywordSearch() {
    _searchController.clear();
    context.read<KeywordsViewModel>().searchKeywords('');
    setState(() {});
    FocusScope.of(context).unfocus();
  }

  Widget _buildRecentSearches() {
    final history = context.watch<UserViewModel>().recentKeywordSearches;
    if (history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: KeywordRecentSearches(
        history: history,
        onTap: _handleRecentSearch,
      ),
    );
  }

  void _handleRecentSearch(RecentSearch search) {
    setState(() => _searchController.text = search.label);
    context.read<KeywordsViewModel>().searchKeywords(search.label);
    FocusScope.of(context).unfocus();
  }
}
