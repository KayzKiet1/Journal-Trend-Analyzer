import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/publication_model.dart';
import '../../../../models/trend_data_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../../viewmodels/publication_bookmark_view_model.dart';
import '../../../../viewmodels/publication_view_model.dart';
import '../../../../widgets/publication_card.dart';
import '../home_formatters.dart';
import 'home_empty_state.dart';
import 'home_metric_tile.dart';
import 'home_notice.dart';
import 'home_rank_section.dart';

class HomeTopicDashboard extends StatelessWidget {
  final bool isLoading;
  final String error;
  final int totalWorks;
  final double averageCitations;
  final int? peakYear;
  final List<Publication> publications;
  final List<TrendData> trends;
  final Map<String, int> topAuthors;
  final Map<String, int> topJournals;
  final int maxJournalsDisplay;
  final String lastSearchText;
  final bool isLoadingMorePublications;
  final WorkSearchPublicationSort selectedPublicationSort;
  final ValueChanged<WorkSearchPublicationSort> onPublicationSortChanged;
  final ValueChanged<Publication> onPublicationTap;
  final VoidCallback onViewKeywords;
  final VoidCallback onExploreJournals;

  const HomeTopicDashboard({
    super.key,
    required this.isLoading,
    required this.error,
    required this.totalWorks,
    required this.averageCitations,
    required this.peakYear,
    required this.publications,
    required this.trends,
    required this.topAuthors,
    required this.topJournals,
    required this.maxJournalsDisplay,
    required this.lastSearchText,
    required this.isLoadingMorePublications,
    required this.selectedPublicationSort,
    required this.onPublicationSortChanged,
    required this.onPublicationTap,
    required this.onViewKeywords,
    required this.onExploreJournals,
  });

  @override
  Widget build(BuildContext context) {
    final hasData =
        totalWorks > 0 || publications.isNotEmpty || trends.isNotEmpty;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xl),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (error.isNotEmpty && !hasData) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
        child: HomeNotice(message: error, icon: Icons.error),
      );
    }

    if (!hasData) {
      return HomeEmptyState(lastSearchText: lastSearchText);
    }

    final topPublication = publications.isEmpty ? null : publications.first;
    final topAuthor = firstEntry(topAuthors);
    final topJournal = firstEntry(topJournals);
    final visibleTopJournals = Map<String, int>.fromEntries(
      topJournals.entries.take(maxJournalsDisplay),
    );
    final visibleTopAuthors = Map<String, int>.fromEntries(
      topAuthors.entries.take(maxJournalsDisplay),
    );
    final journalSubtitle = _visibleSummary(
      visibleTopJournals.length,
      topJournals.length,
      'journals',
    );
    final authorSubtitle = _visibleSummary(
      visibleTopAuthors.length,
      topAuthors.length,
      'authors',
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOPIC RESEARCH OVERVIEW', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              final cards = [
                HomeMetricTile(
                  label: 'Total publications',
                  value: compactCount(totalWorks),
                  icon: Icons.library_books_outlined,
                ),
                HomeMetricTile(
                  label: 'Average citations',
                  value: averageCitations.toStringAsFixed(1),
                  icon: Icons.format_quote_outlined,
                ),
                HomeMetricTile(
                  label: 'Peak year',
                  value: peakYear?.toString() ?? '-',
                  icon: Icons.timeline_outlined,
                ),
                HomeMetricTile(
                  label: 'Top author',
                  value: topAuthor?.key ?? '-',
                  icon: Icons.person_outline,
                ),
              ];

              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 1.45 : 1.12,
                children: cards,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final keywordButton = FilledButton.icon(
                onPressed: onViewKeywords,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('View keyword analysis'),
              );
              final journalButton = OutlinedButton.icon(
                onPressed: onExploreJournals,
                icon: const Icon(Icons.book_outlined),
                label: const Text('Explore journals'),
              );

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    keywordButton,
                    const SizedBox(height: AppSpacing.sm),
                    journalButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: keywordButton),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: journalButton),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final sections = [
                HomeRankSection(
                  title: 'Top contributing authors',
                  subtitle: authorSubtitle,
                  data: visibleTopAuthors,
                  icon: Icons.person_outline,
                ),
                HomeRankSection(
                  title: 'Top journals',
                  subtitle: journalSubtitle,
                  data: visibleTopJournals,
                  icon: Icons.book_outlined,
                ),
              ];

              if (!isWide) {
                return Column(
                  children: [
                    sections[0],
                    const SizedBox(height: AppSpacing.md),
                    sections[1],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: sections[0]),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: sections[1]),
                ],
              );
            },
          ),
          if (topJournal != null) ...[
            const SizedBox(height: AppSpacing.md),
            HomeNotice(
              message:
                  'Leading journal: ${topJournal.key} (${compactCount(topJournal.value)} publications)',
              icon: Icons.workspace_premium_outlined,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Text('PUBLICATIONS', style: AppTextStyles.h2);
              final sortControl = SegmentedButton<WorkSearchPublicationSort>(
                segments: WorkSearchPublicationSort.values
                    .map(
                      (sort) => ButtonSegment(
                        value: sort,
                        icon: Icon(
                          sort == WorkSearchPublicationSort.newest
                              ? Icons.update
                              : Icons.format_quote,
                          size: 16,
                        ),
                        label: Text(sort.label),
                      ),
                    )
                    .toList(),
                selected: {selectedPublicationSort},
                onSelectionChanged: (selection) =>
                    onPublicationSortChanged(selection.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(AppTextStyles.labelCaps),
                  foregroundColor: const WidgetStatePropertyAll(
                    AppColors.textPrimary,
                  ),
                ),
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: AppSpacing.sm),
                    sortControl,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  sortControl,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (topPublication == null)
            const HomeNotice(
              message: 'No publication data available.',
              icon: Icons.article,
            )
          else
            Consumer<PublicationBookmarkViewModel>(
              builder: (context, bookmarks, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...publications.map(
                    (publication) => PublicationCard(
                      title: publication.title,
                      year: publication.publicationYear.toString(),
                      journal: publication.journalName,
                      authors: publication.authorsString,
                      citations: publication.citedByCount,
                      isBookmarked: bookmarks.isBookmarked(publication.id),
                      onBookmarkToggle: () =>
                          bookmarks.toggleBookmark(publication),
                      onTap: () => onPublicationTap(publication),
                    ),
                  ),
                  if (isLoadingMorePublications) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _visibleSummary(int visibleCount, int totalCount, String label) {
    if (totalCount == 0) return 'No $label found';
    if (visibleCount >= totalCount) return 'Showing all $totalCount $label';
    return 'Showing $visibleCount of $totalCount $label';
  }
}
