import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/journal_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../viewmodels/journal_library_view_model.dart';
import '../../viewmodels/journal_detail_view_model.dart';
import '../../widgets/loading_widget.dart';
import 'widgets/detail/journal_detail_content.dart';

class JournalDetailScreen extends StatefulWidget {
  final String journalId;
  final String journalName;
  final List<String> topicIds;
  final String? topicLabel;
  final Journal? journalForTesting;

  const JournalDetailScreen({
    super.key,
    required this.journalId,
    required this.journalName,
    this.topicIds = const [],
    this.topicLabel,
    this.journalForTesting,
  });

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  static const int _minimumChartYear = 1995;

  final ScrollController _scrollController = ScrollController();
  late final JournalDetailViewModel _viewModel;
  int? _selectedChartStartYear;

  int get _currentYear => DateTime.now().year;

  int get _lastTenStartYear {
    final startYear = _currentYear - 9;
    return startYear < _minimumChartYear ? _minimumChartYear : startYear;
  }

  int get _chartStartYear {
    return _selectedChartStartYear ?? _lastTenStartYear;
  }

  String get _chartRangeLabel {
    final years =
        _viewModel.publicationTrends
            .where(
              (trend) =>
                  trend.count > 0 &&
                  trend.year >= _chartStartYear &&
                  trend.year <= _currentYear,
            )
            .map((trend) => trend.year)
            .toList()
          ..sort();
    final endYear = years.isEmpty ? _currentYear : years.last;
    if (_chartStartYear == endYear) return endYear.toString();
    return '$_chartStartYear-$endYear';
  }

  @override
  void initState() {
    super.initState();
    _viewModel = JournalDetailViewModel()..addListener(_handleViewModelChanged);
    _viewModel.load(
      journalId: widget.journalId,
      journalName: widget.journalName,
      topicIds: widget.topicIds,
      chartStartYear: _chartStartYear,
      journalForTesting: widget.journalForTesting,
    );
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) return;
    if (!_viewModel.isLoading &&
        _viewModel.errorMessage.isEmpty &&
        _viewModel.journal != null) {
      context.read<JournalLibraryViewModel>().addRecentViewed(
        _viewModel.journal!,
      );
    }
  }

  void _handleChartStartYearChanged(int startYear) {
    if (startYear == _chartStartYear) return;
    setState(() => _selectedChartStartYear = startYear);
    _viewModel.loadChartRange(startYear: startYear, topicIds: widget.topicIds);
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Scaffold(
            body: LoadingWidget(
              message: 'Loading journal profile from OpenAlex...',
            ),
          );
        }

        if (_viewModel.errorMessage.isNotEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.journalName)),
            body: Center(child: Text(_viewModel.errorMessage)),
          );
        }

        final journal = _viewModel.journal;
        final library = context.watch<JournalLibraryViewModel>();
        final isFavorite = journal != null && library.isFavorite(journal.id);
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              journal?.name ?? widget.journalName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            elevation: 0,
            actions: [
              if (journal != null)
                IconButton(
                  tooltip: isFavorite ? 'Remove from library' : 'Save journal',
                  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                  onPressed: () => library.toggleFavorite(journal),
                ),
            ],
          ),
          body: SingleChildScrollView(
            key: const Key('journal_detail_content'),
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: JournalDetailContent(
                  journal: journal,
                  fallbackName: widget.journalName,
                  topicLabel: widget.topicLabel,
                  publicationTrends: _viewModel.publicationTrends,
                  citationTrends: _viewModel.citationTrends,
                  yearlyData: _viewModel.yearlyData,
                  topTopics: _viewModel.topTopics,
                  topAuthors: _viewModel.topAuthors,
                  chartStartYear: _chartStartYear,
                  chartRangeLabel: _chartRangeLabel,
                  fullChartStartYear: _minimumChartYear,
                  lastTenChartStartYear: _lastTenStartYear,
                  isYearlyDataLoading: _viewModel.isLoadingYearlyData,
                  onChartStartYearChanged: _handleChartStartYearChanged,
                  isFavorite: isFavorite,
                  onToggleFavorite: library.toggleFavorite,
                  onOpenLink: _launchUrl,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
