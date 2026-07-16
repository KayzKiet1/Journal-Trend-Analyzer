import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../viewmodels/journal_library_view_model.dart';
import '../../viewmodels/publication_view_model.dart';
import '../../widgets/loading_widget.dart';
import '../../models/journal_model.dart';
import 'compare_journals_screen.dart';
import 'journal_detail_screen.dart';
import 'widgets/list/journal_card.dart';
import 'widgets/list/journal_compare_bar.dart';
import 'widgets/list/journal_feedback.dart';
import 'widgets/list/journal_hero_header.dart';
import 'widgets/list/journal_search_panel.dart';

class JournalsScreen extends StatefulWidget {
  const JournalsScreen({super.key});

  @override
  State<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends State<JournalsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _journalSearchController =
      TextEditingController();
  final List<Journal> _compareSelection = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<PublicationViewModel>();
      _journalSearchController.text = controller.journalSearchText;
      _loadInitialJournals();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _journalSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final controller = context.read<PublicationViewModel>();
      if (!controller.isLoadingMoreJournals &&
          controller.hasMoreJournalSources) {
        controller.searchJournals(controller.journalSearchText, loadMore: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Journals',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Consumer<PublicationViewModel>(
        builder: (context, controller, child) {
          final isCurrentResultEmpty = controller.journalSources.isEmpty;
          final isLoading = controller.isLoadingJournals;
          final errorMessage = controller.journalErrorMessage;

          if (isLoading && isCurrentResultEmpty) {
            return const LoadingWidget(
              message: 'Loading journals from OpenAlex...',
            );
          }

          if (errorMessage.isNotEmpty && isCurrentResultEmpty) {
            return JournalSearchError(
              message: errorMessage,
              onRetry: _retrySearch,
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: _buildResultList(controller),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultList(PublicationViewModel controller) {
    final library = context.watch<JournalLibraryViewModel>();
    final visibleSources = controller.journalSources;

    if (controller.journalSources.isEmpty && !controller.isLoadingJournals) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const JournalHeroHeader(),
          const SizedBox(height: AppSpacing.lg),
          _buildJournalSearchPanel(controller),
          _buildCompareBar(),
          JournalEmptyState(
            hasQuery: _journalSearchController.text.trim().isNotEmpty,
            onClear: _clearJournalSearch,
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount:
          visibleSources.length +
          1 +
          (controller.hasMoreJournalSources ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const JournalHeroHeader(),
              const SizedBox(height: AppSpacing.lg),
              _buildJournalSearchPanel(controller),
              _buildCompareBar(),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        }

        final sourceIndex = index - 1;
        if (sourceIndex == visibleSources.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final source = visibleSources[sourceIndex];
        final isSelected = _isSelectedForCompare(source);
        final isFavorite = library.isFavorite(source.id);
        return JournalCard(
          journal: source,
          isSelectedForCompare: isSelected,
          isFavorite: isFavorite,
          onCompareToggle: () => _toggleCompareSelection(source),
          onFavoriteToggle: () => library.toggleFavorite(source),
          onTap: () => _openJournal(source),
        );
      },
    );
  }

  void _loadInitialJournals() {
    if (!mounted) return;

    final controller = context.read<PublicationViewModel>();
    if (controller.journalSources.isEmpty &&
        !controller.isLoadingJournals &&
        controller.journalErrorMessage.isEmpty) {
      controller.searchJournals('');
    }
  }

  void _retrySearch() {
    final controller = context.read<PublicationViewModel>();
    controller.cancelActiveSearch();
    controller.searchJournals(_journalSearchController.text);
  }

  Widget _buildJournalSearchPanel(PublicationViewModel controller) {
    return JournalSearchPanel(
      textController: _journalSearchController,
      isLoading: controller.isLoadingJournals,
      resultQuery: controller.journalSearchText.trim(),
      resultTotal: controller.journalSourcesTotal,
      resultLoaded: controller.journalSources.length,
      onClear: _clearJournalSearch,
      onSubmit: _submitJournalSearch,
      onChanged: (_) => setState(() {}),
    );
  }

  void _submitJournalSearch() {
    context.read<PublicationViewModel>().searchJournals(
      _journalSearchController.text,
    );
    FocusScope.of(context).unfocus();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _clearJournalSearch() {
    setState(_journalSearchController.clear);
    context.read<PublicationViewModel>().searchJournals('');
    FocusScope.of(context).unfocus();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildCompareBar() {
    return JournalCompareBar(
      selectedJournals: List<Journal>.unmodifiable(_compareSelection),
      onClear: () => setState(_compareSelection.clear),
      onCompare: _openCompareScreen,
    );
  }

  bool _isSelectedForCompare(Journal journal) {
    return _compareSelection.any((item) => item.id == journal.id);
  }

  void _toggleCompareSelection(Journal journal) {
    setState(() {
      final existingIndex = _compareSelection.indexWhere(
        (item) => item.id == journal.id,
      );
      if (existingIndex >= 0) {
        _compareSelection.removeAt(existingIndex);
        return;
      }

      if (_compareSelection.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select up to 2 journals for comparison.'),
          ),
        );
        return;
      }

      _compareSelection.add(journal);
    });
  }

  void _openCompareScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompareJournalsScreen(
          journals: List<Journal>.from(_compareSelection),
        ),
      ),
    );
  }

  void _openJournal(Journal journal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          final controller = context.read<PublicationViewModel>();
          return JournalDetailScreen(
            journalId: journal.id,
            journalName: journal.name,
            topicIds: const <String>[],
            topicLabel: null,
            journalForTesting: controller.hasTestingFixtures ? journal : null,
          );
        },
      ),
    );
  }
}
