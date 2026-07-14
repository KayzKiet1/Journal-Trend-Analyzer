import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../viewmodels/keyword_detail_view_model.dart';
import '../publications/publication_detail_screen.dart';
import 'widgets/common/keyword_notice.dart';
import 'widgets/detail/keyword_detail_content.dart';

class KeywordDetailScreen extends StatefulWidget {
  final String keywordId;
  final String keywordName;
  final int keywordCount;
  final List<String> topicIds;
  final String topicLabel;
  final String workQuery;

  const KeywordDetailScreen({
    super.key,
    required this.keywordId,
    required this.keywordName,
    required this.keywordCount,
    required this.topicIds,
    required this.topicLabel,
    required this.workQuery,
  });

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> {
  late final KeywordDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = KeywordDetailViewModel();
    _viewModel.loadKeywordDetail(
      keywordId: widget.keywordId,
      keywordName: widget.keywordName,
      topicIds: widget.topicIds,
      workQuery: widget.workQuery,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Keyword Analysis')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) => _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_viewModel.error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: KeywordNotice(message: _viewModel.error, plain: true),
      );
    }

    return KeywordDetailContent(
      keywordName: widget.keywordName,
      keywordCount: widget.keywordCount,
      topicIds: widget.topicIds,
      topicLabel: widget.topicLabel,
      totalPublications: _viewModel.totalPublications,
      trends: _viewModel.trends,
      journals: _viewModel.journals,
      authors: _viewModel.authors,
      publications: _viewModel.publications,
      onPublicationTap: (publication) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PublicationDetailScreen(publication: publication),
          ),
        );
      },
    );
  }
}
