import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/journal_library_controller.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/app_text_field.dart';
import '../models/journal_model.dart';
import 'compare_journals_screen.dart';
import 'publication_detail_screen.dart';
import 'journal_detail_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String topic;
  final String category;
  final String? authorId;

  const SearchResultScreen({
    super.key,
    required this.topic,
    this.category = 'Works',
    this.authorId,
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  static const Duration _searchUiTimeout = Duration(seconds: 12);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _journalSearchController =
      TextEditingController();
  final List<Journal> _compareSelection = [];
  Timer? _searchTimeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.category == 'Sources') {
        final controller = context.read<PublicationController>();
        _journalSearchController.text = controller.journalSearchText;
      }
      _runSearchFromWidget();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(SearchResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topic != oldWidget.topic ||
        widget.category != oldWidget.category) {
      _compareSelection.clear();
      _runSearchFromWidget();
    }
  }

  @override
  void dispose() {
    _searchTimeoutTimer?.cancel();
    _journalSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final controller = context.read<PublicationController>();
      if (widget.category == 'Sources') {
        if (!controller.isLoadingMoreJournals &&
            controller.hasMoreJournalSources) {
          controller.searchJournals(
            controller.journalSearchText,
            loadMore: true,
          );
        }
      } else if (!controller.isLoadingMore &&
          controller.hasMoreFor(widget.category)) {
        if (widget.category == 'AuthorWorks' && widget.authorId != null) {
          controller.searchByAuthor(
            widget.authorId!,
            widget.topic,
            loadMore: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = widget.topic;

    if (widget.category == 'AuthorWorks') {
      displayTitle = 'Papers by ${widget.topic}';
    } else if (widget.category == 'Sources') {
      displayTitle = 'Journals';
    } else {
      displayTitle = '${widget.category}: ${widget.topic}';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.read<PublicationController>().setSelectedIndex(0);
              }
            },
            tooltip: 'New search',
          ),
        ],
      ),
      body: Consumer<PublicationController>(
        builder: (context, controller, child) {
          final isCurrentResultEmpty = widget.category == 'Sources'
              ? controller.journalSources.isEmpty
              : controller.publications.isEmpty;
          final isLoading = widget.category == 'Sources'
              ? controller.isLoadingJournals
              : controller.isLoading;
          final errorMessage = widget.category == 'Sources'
              ? controller.journalErrorMessage
              : controller.errorMessage;

          if (isLoading && isCurrentResultEmpty) {
            return LoadingWidget(
              message: widget.category == 'Sources'
                  ? 'Loading journals from OpenAlex...'
                  : 'Loading data from OpenAlex...',
            );
          }

          if (errorMessage.isNotEmpty && isCurrentResultEmpty) {
            return _buildSearchError(errorMessage);
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

  Widget _buildResultList(PublicationController controller) {
    switch (widget.category) {
      case 'AuthorWorks':
        if (controller.publications.isEmpty && !controller.isLoading) {
          return const EmptyStateWidget(message: 'No publications found.');
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount:
              controller.publications.length +
              (controller.hasMoreFor(widget.category) ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.publications.length) {
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

            final pub = controller.publications[index];
            return PublicationCard(
              title: pub.title,
              authors: pub.authorsString,
              journal: pub.journalName,
              year: pub.publicationYear.toString(),
              citations: pub.citedByCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PublicationDetailScreen(publication: pub),
                  ),
                );
              },
            );
          },
        );
      case 'Sources':
        if (controller.journalSources.isEmpty &&
            !controller.isLoadingJournals) {
          return Column(
            children: [
              _buildCompareBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _buildJournalSearchPanel(controller),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLibraryPanel(),
                    _buildJournalEmptyState(),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            _buildCompareBar(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount:
                    controller.journalSources.length +
                    1 +
                    (controller.hasMoreJournalSources ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildJournalSearchPanel(controller),
                        _buildLibraryPanel(),
                      ],
                    );
                  }

                  final sourceIndex = index - 1;
                  if (sourceIndex == controller.journalSources.length) {
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

                  final source = controller.journalSources[sourceIndex];
                  final isSelected = _isSelectedForCompare(source);
                  final library = context.watch<JournalLibraryController>();
                  final isFavorite = library.isFavorite(source.id);
                  return _buildEntityCard(
                    journal: source,
                    isSelectedForCompare: isSelected,
                    isFavorite: isFavorite,
                    onCompareToggle: () => _toggleCompareSelection(source),
                    onFavoriteToggle: () => library.toggleFavorite(source),
                    onTap: () => _openJournal(source),
                  );
                },
              ),
            ),
          ],
        );
      default:
        return const EmptyStateWidget(message: 'No matching data.');
    }
  }

  void _runSearchFromWidget() {
    if (!mounted) return;

    final topic = widget.topic.trim();
    if (widget.category == 'Sources') {
      final controller = context.read<PublicationController>();
      if (controller.journalSources.isEmpty &&
          !controller.isLoadingJournals &&
          controller.journalErrorMessage.isEmpty) {
        controller.searchJournals('');
      }
      return;
    }

    _searchTimeoutTimer?.cancel();
    final controller = context.read<PublicationController>();
    if (widget.category == 'AuthorWorks' && widget.authorId != null) {
      controller.searchByAuthor(widget.authorId!, topic);
    } else {
      _searchTimeoutTimer = Timer(_searchUiTimeout, () {
        if (!mounted) return;

        final currentController = context.read<PublicationController>();
        final stillWaitingForThisSearch =
            widget.category == 'Sources' &&
            widget.topic.trim() == topic &&
            currentController.isLoading &&
            currentController.sources.isEmpty;

        if (stillWaitingForThisSearch) {
          currentController.cancelActiveSearch(
            message:
                'OpenAlex phản hồi quá lâu cho "$topic". Vui lòng kiểm tra mạng hoặc thử lại.',
          );
        }
      });
      controller.search(topic, widget.category).whenComplete(() {
        if (!mounted || widget.topic.trim() != topic) return;
        _searchTimeoutTimer?.cancel();
      });
    }
  }

  void _retrySearch() {
    _searchTimeoutTimer?.cancel();
    final controller = context.read<PublicationController>();
    controller.cancelActiveSearch();

    if (widget.category == 'Sources') {
      controller.searchJournals(_journalSearchController.text);
    } else {
      _runSearchFromWidget();
    }
  }

  Widget _buildJournalSearchPanel(PublicationController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;
          final searchField = AppTextField(
            fieldKey: const Key('journal_search_field'),
            controller: _journalSearchController,
            hintText: 'Search by journal name or publisher',
            prefixIcon: Icons.manage_search,
            suffixIcon: _journalSearchController.text.isEmpty
                ? null
                : Icons.close,
            onSuffixTap: _clearJournalSearch,
            onChanged: (_) => setState(() {}),
            onSubmitted: _submitJournalSearch,
          );
          final searchButton = ElevatedButton.icon(
            key: const Key('journal_search_button'),
            onPressed: controller.isLoadingJournals
                ? null
                : _submitJournalSearch,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Search'),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OPENALEX JOURNAL SOURCES',
                      style: AppTextStyles.labelCaps,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Discover Journals', style: AppTextStyles.h1),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Search OpenAlex sources by journal name or publisher.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (isCompact)
                      Column(
                        children: [
                          searchField,
                          const SizedBox(height: AppSpacing.sm),
                          Row(children: [Expanded(child: searchButton)]),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: AppSpacing.sm),
                          searchButton,
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildJournalResultSummary(controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJournalResultSummary(PublicationController controller) {
    final query = controller.journalSearchText.trim();
    final total = controller.journalSourcesTotal;
    final loaded = controller.journalSources.length;
    final label = query.isEmpty
        ? 'Showing popular journal sources'
        : 'Showing results for "$query"';

    return Row(
      children: [
        const Icon(
          Icons.library_books_outlined,
          size: 16,
          color: AppColors.accent,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            total > 0 ? '$label • $loaded of $total loaded' : label,
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _submitJournalSearch() {
    context.read<PublicationController>().searchJournals(
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
    context.read<PublicationController>().searchJournals('');
    FocusScope.of(context).unfocus();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildSearchError(String message) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _retrySearch,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJournalEmptyState() {
    final hasQuery = _journalSearchController.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 40,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No journals found', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasQuery
                ? 'Try a broader source name or clear your search.'
                : 'OpenAlex did not return journal sources yet.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (hasQuery) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _clearJournalSearch,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLibraryPanel() {
    return Consumer<JournalLibraryController>(
      builder: (context, library, child) {
        if (library.favorites.isEmpty && library.recentViewed.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (library.favorites.isNotEmpty) ...[
              _buildJournalStrip(
                title: 'FAVORITE JOURNALS',
                journals: library.favorites,
                icon: Icons.star,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (library.recentViewed.isNotEmpty) ...[
              _buildJournalStrip(
                title: 'RECENTLY VIEWED',
                journals: library.recentViewed,
                icon: Icons.history,
                trailing: TextButton(
                  onPressed: library.clearRecentViewed,
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        );
      },
    );
  }

  Widget _buildJournalStrip({
    required String title,
    required List<Journal> journals,
    required IconData icon,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title, style: AppTextStyles.labelCaps)),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: journals.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _buildSavedJournalCard(journals[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavedJournalCard(Journal journal) {
    return InkWell(
      onTap: () => _openJournal(journal),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              journal.name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '${journal.worksCount} publications • ${journal.citedByCount} citations',
              style: AppTextStyles.labelCaps.copyWith(fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareBar() {
    final canCompare = _compareSelection.length == 2;
    final hasSelection = _compareSelection.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final countLabel = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.compare_arrows, size: 18, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                hasSelection
                    ? 'Selected ${_compareSelection.length}/2 journals'
                    : 'Select 2 journals to compare',
                style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
        final actions = Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.end,
          children: [
            if (_compareSelection.isNotEmpty)
              TextButton(
                onPressed: () => setState(_compareSelection.clear),
                child: const Text('Clear'),
              ),
            ElevatedButton.icon(
              onPressed: canCompare ? _openCompareScreen : null,
              icon: const Icon(Icons.stacked_line_chart, size: 16),
              label: const Text('Compare'),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppSpacing.md : AppSpacing.lg,
            vertical: hasSelection ? AppSpacing.sm : AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: hasSelection ? AppColors.accentLight : AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: hasSelection ? AppColors.accent : AppColors.border,
              ),
            ),
            boxShadow: hasSelection
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    countLabel,
                    const SizedBox(height: AppSpacing.sm),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: countLabel),
                    const SizedBox(width: AppSpacing.sm),
                    actions,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEntityCard({
    required Journal journal,
    bool isSelectedForCompare = false,
    bool isFavorite = false,
    VoidCallback? onCompareToggle,
    VoidCallback? onFavoriteToggle,
    VoidCallback? onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final typeLabel = (journal.type?.trim().isNotEmpty == true)
            ? journal.type!.toUpperCase()
            : 'JOURNAL';
        final leading = Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelectedForCompare
                ? AppColors.accent
                : AppColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.book_outlined,
            color: isSelectedForCompare ? AppColors.surface : AppColors.accent,
            size: 24,
          ),
        );
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              journal.name,
              style: AppTextStyles.h2.copyWith(fontSize: isCompact ? 16 : 18),
              maxLines: isCompact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              journal.publisher ?? 'OpenAlex journal source',
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _buildMetricBadge(
                  Icons.article_outlined,
                  '${_compactCount(journal.worksCount)} publications',
                ),
                _buildMetricBadge(
                  Icons.format_quote,
                  '${_compactCount(journal.citedByCount)} citations',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    typeLabel,
                    style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        );
        final actionButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onFavoriteToggle != null)
              Tooltip(
                message: isFavorite ? 'Remove from library' : 'Save journal',
                child: IconButton(
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? AppColors.accent : AppColors.secondary,
                  ),
                ),
              ),
            if (onCompareToggle != null)
              Tooltip(
                message: isSelectedForCompare
                    ? 'Remove from comparison'
                    : 'Add to comparison',
                child: IconButton(
                  onPressed: onCompareToggle,
                  icon: Icon(
                    isSelectedForCompare
                        ? Icons.check_box
                        : Icons.add_box_outlined,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        );
        final openHint = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Details',
                style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: AppColors.secondary,
              ),
            ],
          ),
        );
        final actions = isCompact
            ? Row(children: [actionButtons, const Spacer(), openHint])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  actionButtons,
                  const SizedBox(height: AppSpacing.sm),
                  openHint,
                ],
              );
        final cardContent = isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leading,
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: content),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  actions,
                ],
              )
            : Row(
                children: [
                  leading,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: content),
                  const SizedBox(width: AppSpacing.sm),
                  actions,
                ],
              );

        return Material(
          key: Key('journal_card_${journal.id}'),
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelectedForCompare
                    ? AppColors.accentLight
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelectedForCompare
                      ? AppColors.accent
                      : AppColors.border,
                  width: AppSpacing.borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: cardContent,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.accent,
              fontSize: 10,
            ),
          ),
        ],
      ),
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

  String _compactCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
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
          final controller = context.read<PublicationController>();
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
