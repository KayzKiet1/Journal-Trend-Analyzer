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
  final ScrollController _scrollController = ScrollController();
  final List<Journal> _compareSelection = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.category == 'AuthorWorks' && widget.authorId != null) {
        context.read<PublicationController>().searchByAuthor(
          widget.authorId!,
          widget.topic,
        );
      } else {
        context.read<PublicationController>().search(
          widget.topic,
          widget.category,
        );
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(SearchResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topic != oldWidget.topic ||
        widget.category != oldWidget.category) {
      _compareSelection.clear();
      if (widget.category == 'AuthorWorks' && widget.authorId != null) {
        context.read<PublicationController>().searchByAuthor(
          widget.authorId!,
          widget.topic,
        );
      } else {
        context.read<PublicationController>().search(
          widget.topic,
          widget.category,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final controller = context.read<PublicationController>();
      if (!controller.isLoadingMore && controller.hasMoreFor(widget.category)) {
        if (widget.category == 'AuthorWorks' && widget.authorId != null) {
          controller.searchByAuthor(
            widget.authorId!,
            widget.topic,
            loadMore: true,
          );
        } else if (widget.category == 'Sources') {
          controller.search(widget.topic, widget.category, loadMore: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = widget.topic;

    if (widget.category == 'AuthorWorks') {
      displayTitle = 'Bài báo của ${widget.topic}';
    } else if (widget.category == 'Sources') {
      displayTitle = 'Journals: ${widget.topic}';
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
            tooltip: 'Tìm kiếm mới',
          ),
        ],
      ),
      body: Consumer<PublicationController>(
        builder: (context, controller, child) {
          final isCurrentResultEmpty = widget.category == 'Sources'
              ? controller.sources.isEmpty
              : controller.publications.isEmpty;

          if (controller.isLoading && isCurrentResultEmpty) {
            return const LoadingWidget();
          }

          if (controller.errorMessage.isNotEmpty && isCurrentResultEmpty) {
            return Center(child: Text(controller.errorMessage));
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
          return const EmptyStateWidget(message: 'Không tìm thấy bài báo nào.');
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
        if (controller.sources.isEmpty && !controller.isLoading) {
          return Column(
            children: [
              _buildCompareBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _buildLibraryPanel(),
                    const EmptyStateWidget(
                      message: 'Không tìm thấy nguồn nào.',
                    ),
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
                    controller.sources.length +
                    1 +
                    (controller.hasMoreFor(widget.category) ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildLibraryPanel();
                  }

                  final sourceIndex = index - 1;
                  if (sourceIndex == controller.sources.length) {
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

                  final source = controller.sources[sourceIndex];
                  final isSelected = _isSelectedForCompare(source);
                  final library = context.watch<JournalLibraryController>();
                  final isFavorite = library.isFavorite(source.id);
                  return _buildEntityCard(
                    title: source.name,
                    subtitle: source.publisher ?? source.type ?? 'Source',
                    trailing: '${source.worksCount} works',
                    icon: Icons.book_outlined,
                    meta: '${source.citedByCount} citations',
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
        return const EmptyStateWidget(message: 'Category unknown');
    }
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
                title: 'RECENT VIEWED JOURNALS',
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
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
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
              '${journal.worksCount} works • ${journal.citedByCount} citations',
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
                'Selected ${_compareSelection.length}/2 journals',
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
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.25),
              ),
            ),
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
    required String title,
    required String subtitle,
    required String trailing,
    required IconData icon,
    required String meta,
    bool isSelectedForCompare = false,
    bool isFavorite = false,
    VoidCallback? onCompareToggle,
    VoidCallback? onFavoriteToggle,
    VoidCallback? onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final leading = Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accent, size: 24),
        );
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h2.copyWith(fontSize: isCompact ? 16 : 18),
              maxLines: isCompact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.format_quote,
                  size: 12,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    meta,
                    style: AppTextStyles.labelCaps.copyWith(
                      color: AppColors.accent,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        );
        final actions = Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.end,
          children: [
            if (onFavoriteToggle != null)
              Tooltip(
                message: isFavorite ? 'Bỏ lưu journal' : 'Lưu journal',
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
                    ? 'Bỏ khỏi so sánh'
                    : 'Thêm vào so sánh',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                trailing,
                style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
              ),
            ),
          ],
        );

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.secondary,
                width: AppSpacing.borderWidth,
              ),
            ),
            child: isCompact
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
                      Align(alignment: Alignment.centerRight, child: actions),
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
                  ),
          ),
        );
      },
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
            content: Text('Chỉ chọn tối đa 2 journal để so sánh.'),
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
        builder: (context) => JournalDetailScreen(
          journalId: journal.id,
          journalName: journal.name,
        ),
      ),
    );
  }
}
