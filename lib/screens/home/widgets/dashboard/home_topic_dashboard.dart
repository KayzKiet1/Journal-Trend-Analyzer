import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/publication_model.dart';
import '../../../../models/trend_data_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../../viewmodels/publication_bookmark_view_model.dart';
import '../../../../widgets/publication_card.dart';
import '../../../../widgets/year_trend_chart.dart';
import '../home_formatters.dart';
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
  final ValueChanged<Publication> onPublicationTap;

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
    required this.onPublicationTap,
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
      return const SizedBox(height: AppSpacing.xl);
    }

    final topPublication = publications.isEmpty ? null : publications.first;
    final topAuthor = firstEntry(topAuthors);
    final topJournal = firstEntry(topJournals);
    final visibleTopJournals = Map<String, int>.fromEntries(
      topJournals.entries.take(maxJournalsDisplay),
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
                childAspectRatio: isWide ? 1.45 : 1.25,
                children: cards,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          YearTrendChart(
            trends: trends,
            forceLineChart: true,
            startYear: 1995,
            rangeLabel: '1995-${DateTime.now().year}',
            title: 'Publication Trend Over Time',
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final sections = [
                HomeRankSection(
                  title: 'Top contributing authors',
                  data: topAuthors,
                  icon: Icons.person_outline,
                ),
                HomeRankSection(
                  title: 'Top journals (limit $maxJournalsDisplay)',
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
          Text('MOST INFLUENTIAL PUBLICATIONS', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.md),
          if (topPublication == null)
            const HomeNotice(
              message: 'Không có dữ liệu công bố.',
              icon: Icons.article,
            )
          else
            Consumer<PublicationBookmarkViewModel>(
              builder: (context, bookmarks, _) => Column(
                children: publications
                    .take(5)
                    .map(
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
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
