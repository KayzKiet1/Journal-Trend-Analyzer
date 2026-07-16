import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/firebase_view_model.dart';
import '../../viewmodels/publication_view_model.dart';
import '../../viewmodels/keywords_view_model.dart';
import 'keyword_detail_screen.dart';
import 'widgets/dashboard/keyword_dashboard_content.dart';
import 'widgets/dashboard/keyword_empty_state.dart';
import 'widgets/dashboard/keyword_fixture_dashboard.dart';
import 'widgets/detail/keyword_fixture_detail_screen.dart';

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<KeywordsViewModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Keyword Trends')),
      body: _buildTopicKeywordDashboard(context, viewModel),
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
    final query = controller.currentWorkQuery;
    final topicIds = controller.currentWorkTopicIds;

    if (controller.isLoadingTopicDashboard) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (controller.keywordFixtures.isNotEmpty) {
      return KeywordFixtureDashboard(
        keywords: controller.keywordFixtures,
        topicIds: controller.currentTopicIds,
        scopeLabel: controller.currentWorkScopeLabel,
        onKeywordTap: _openKeywordDetail,
      );
    }

    if (query.isEmpty) {
      return KeywordEmptyState(
        lastSearchText: controller.lastSearchText,
        onGoHome: () =>
            context.read<PublicationViewModel>().setSelectedIndex(0),
      );
    }

    final topicKey = '${query.toLowerCase()}|${topicIds.join('|')}';
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
      scopeLabel: controller.currentWorkScopeLabel,
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
    final keywordId = keyword['id']?.toString() ?? '';
    if (keywordId.isEmpty || controller.currentWorkQuery.isEmpty) {
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
          topicIds: controller.currentWorkTopicIds,
          topicLabel: controller.currentWorkScopeLabel,
          workQuery: controller.currentWorkQuery,
        ),
      ),
    );
  }
}
