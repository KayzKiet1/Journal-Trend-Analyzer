import 'package:flutter/material.dart';
import '../../models/journal_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../viewmodels/compare_journals_view_model.dart';
import 'widgets/compare/compare_journals_content.dart';

class CompareJournalsScreen extends StatefulWidget {
  final List<Journal> journals;

  const CompareJournalsScreen({super.key, required this.journals});

  @override
  State<CompareJournalsScreen> createState() => _CompareJournalsScreenState();
}

class _CompareJournalsScreenState extends State<CompareJournalsScreen> {
  late final CompareJournalsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CompareJournalsViewModel();
    _viewModel.loadComparisonData(widget.journals);
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
      appBar: AppBar(title: const Text('Compare Journals')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(_viewModel.errorMessage, style: AppTextStyles.bodyMedium),
        ),
      );
    }

    if (_viewModel.details.length < 2) {
      return const Center(child: Text('Select 2 journals to compare.'));
    }

    return CompareJournalsContent(
      journals: _viewModel.details,
      topicsByJournal: _viewModel.topicsByJournal,
      currentYear: _viewModel.currentYear,
      excludeFutureYears: _viewModel.excludeFutureYears,
      onExcludeFutureYearsChanged: (value) =>
          _viewModel.excludeFutureYears = value,
      worksCountForCompare: _viewModel.worksCountForCompare,
      citationsForCompare: _viewModel.citationsForCompare,
      avgCitations: _viewModel.avgCitations,
      publicationTrends: _viewModel.publicationTrends,
      citationTrends: _viewModel.citationTrends,
    );
  }
}
