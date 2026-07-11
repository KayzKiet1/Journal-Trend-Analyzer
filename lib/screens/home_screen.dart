import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/publication_controller.dart';
import '../firebase/firebase_analytics_service.dart';
import '../models/research_topic_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/year_trend_chart.dart';
import '../widgets/publication_card.dart';
import 'publication_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAnalyticsService _analyticsService = FirebaseAnalyticsService();
  Timer? _topicDebounce;
  static const List<String> _quickTopics = [
    'Artificial Intelligence',
    'Healthcare',
    'Climate Change',
  ];

  void _handleSearch() {
    final currentController = context.read<PublicationController>();
    if (currentController.isLoadingTopicDashboard) return;

    final selectedTopics = context.read<PublicationController>().selectedTopics;
    if (selectedTopics.isEmpty) {
      _loadTopicSuggestions(_searchController.text);
      return;
    }

    final controller = context.read<PublicationController>();
    final topicLabel = selectedTopics.map((topic) => topic.name).join(', ');
    _analyticsService.logSearchTopic(
      keyword: topicLabel,
      topicCount: selectedTopics.length,
    );
    controller.updateSearchText(topicLabel);
    controller.updateSearchCategory('Sources');
    controller.loadTopicDashboard();

    // Lưu vào lịch sử tìm kiếm nếu có từ khóa
    context.read<UserController>().addTopicSearch(selectedTopics);
  }

  void _onSearchTextChanged(String value) {
    setState(() {});
    final controller = context.read<PublicationController>();
    controller.updateSearchText(value);
    controller.clearTopicSelection();
    _topicDebounce?.cancel();
    _topicDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _loadTopicSuggestions(value);
    });
  }

  void _loadTopicSuggestions(String value) {
    context.read<PublicationController>().loadTopicSuggestions(value);
  }

  void _toggleTopic(ResearchTopic topic) {
    _topicDebounce?.cancel();
    context.read<PublicationController>().toggleTopic(topic);
  }

  void _handleQuickTopic(String topic) {
    _topicDebounce?.cancel();
    setState(() {
      _searchController.text = topic;
    });
    final controller = context.read<PublicationController>();
    controller.updateSearchText(topic);
    controller.loadTopicSuggestions(topic);
  }

  void _clearSearchInput() {
    _topicDebounce?.cancel();
    setState(_searchController.clear);
    final controller = context.read<PublicationController>();
    controller.updateSearchText('');
    controller.clearTopicSelection();
  }

  void _handleRecentTopic(RecentSearch search) {
    _topicDebounce?.cancel();
    setState(() {
      _searchController.text = search.label;
    });
    final controller = context.read<PublicationController>();
    controller.updateSearchText(search.label);

    if (search.topicIds.isNotEmpty) {
      final restoredTopics = <ResearchTopic>[];
      for (var i = 0; i < search.topicIds.length; i++) {
        restoredTopics.add(
          ResearchTopic(
            id: search.topicIds[i],
            name: i < search.topicNames.length
                ? search.topicNames[i]
                : search.topicIds[i],
          ),
        );
      }
      controller.setSelectedTopics(restoredTopics);
      controller.updateSearchCategory('Sources');
      controller.loadTopicDashboard();
      return;
    }

    controller.clearTopicSelection();
    controller.loadTopicSuggestions(search.label);
  }

  @override
  void dispose() {
    _topicDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize search text and category from controller when returning to screen
    final controller = context.read<PublicationController>();
    final lastSearch = controller.lastSearchText;

    if (_searchController.text.isEmpty && lastSearch.isNotEmpty) {
      _searchController.text = lastSearch;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Journal Trend Analyzer'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentLight.withValues(alpha: 0.75),
              AppColors.background,
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroHeader(),
                  const SizedBox(height: AppSpacing.lg),

                  // Search Input Field
                  AppTextField(
                    fieldKey: const Key('home_topic_search_field'),
                    controller: _searchController,
                    hintText: 'Enter a research topic...',
                    prefixIcon: Icons.search,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : Icons.close,
                    onSuffixTap: _clearSearchInput,
                    onChanged: _onSearchTextChanged,
                    onSubmitted: () => _handleSearch(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTopicSuggestions(),
                  const SizedBox(height: AppSpacing.lg),

                  // Search Button
                  Consumer<PublicationController>(
                    builder: (context, controller, child) {
                      final selectedCount = controller.selectedTopics.length;
                      final isLoading = controller.isLoadingTopicDashboard;
                      final isLoadingSuggestions =
                          controller.isLoadingTopicSuggestions;
                      final query = _searchController.text.trim();
                      final hasSelection = selectedCount > 0;
                      final canFindTopics = query.length >= 2;
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: AppButton(
                          key: const Key('home_search_button'),
                          text: isLoading
                              ? 'Loading Research Overview...'
                              : isLoadingSuggestions
                              ? 'Finding Topics...'
                              : !hasSelection
                              ? 'Find Topics'
                              : 'Search Journals by $selectedCount Topics',
                          onPressed:
                              isLoading ||
                                  isLoadingSuggestions ||
                                  (!hasSelection && !canFindTopics)
                              ? null
                              : () {
                                  if (hasSelection) {
                                    _handleSearch();
                                  } else {
                                    _loadTopicSuggestions(query);
                                  }
                                },
                        ),
                      );
                    },
                  ),
                  Consumer<PublicationController>(
                    builder: (context, controller, child) {
                      if (controller.selectedTopics.isNotEmpty ||
                          _searchController.text.trim().isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'Select a topic above before searching journals.',
                          style: AppTextStyles.bodySmall,
                        ),
                      );
                    },
                  ),
                  Consumer<PublicationController>(
                    builder: (context, controller, child) {
                      final selectedTopics = controller.selectedTopics;
                      if (selectedTopics.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SELECTED TOPICS',
                              style: AppTextStyles.labelCaps.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: selectedTopics
                                  .map(
                                    (topic) => _buildSelectedTopicChip(topic),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  _buildTopicDashboard(),

                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      const Icon(
                        Icons.history,
                        color: AppColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('RECENT SEARCHES', style: AppTextStyles.labelCaps),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Consumer<UserController>(
                    builder: (context, userController, child) {
                      final history = userController.recentSearches;

                      if (history.isEmpty) {
                        return Text(
                          'No recent searches yet.',
                          style: AppTextStyles.bodySmall,
                        );
                      }

                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: history
                            .map((search) => _buildTopicChip(search))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primarySoft, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -20,
            child: Icon(
              Icons.auto_graph,
              size: 108,
              color: AppColors.surface.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.surface.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  'OPENALEX RESEARCH DISCOVERY',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.88),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Explore Academic Insights',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.surface,
                  fontSize: 24,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Search by research topic, then explore matching journals from OpenAlex.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.surface.withValues(alpha: 0.86),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicChip(RecentSearch search) {
    return ActionChip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 248),
        child: Text(search.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      onPressed: () => _handleRecentTopic(search),
      avatar: const Icon(Icons.north_west, size: 14),
      backgroundColor: AppColors.surfaceTint,
      surfaceTintColor: AppColors.accentLight,
      elevation: 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      labelStyle: AppTextStyles.labelCaps.copyWith(
        color: AppColors.primary,
        fontSize: 11,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border, width: 1.0),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );
  }

  Widget _buildSelectedTopicChip(ResearchTopic topic) {
    return InputChip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(topic.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      onDeleted: () => _toggleTopic(topic),
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: AppColors.accentLight,
      deleteIconColor: AppColors.accent,
      labelStyle: AppTextStyles.labelCaps.copyWith(
        color: AppColors.primary,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.accent, width: 1.0),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );
  }

  Widget _buildTopicSuggestions() {
    return Consumer<PublicationController>(
      builder: (context, controller, child) {
        final query = _searchController.text.trim();
        if (query.length < 2 &&
            !controller.isLoadingTopicSuggestions &&
            controller.topicSuggestions.isEmpty) {
          return _buildQuickTopics();
        }

        if (controller.isLoadingTopicSuggestions) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.accent,
              backgroundColor: AppColors.accentLight,
            ),
          );
        }

        if (controller.topicSuggestionError.isNotEmpty &&
            controller.topicSuggestions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              controller.topicSuggestionError,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          );
        }

        if (controller.topicSuggestions.isEmpty) {
          return _buildQuickTopics();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('RELATED TOPICS', style: AppTextStyles.labelCaps),
                ),
                if (controller.selectedTopics.isNotEmpty)
                  TextButton.icon(
                    onPressed: controller.clearSelectedTopics,
                    icon: const Icon(Icons.close, size: 16),
                    label: Text(
                      '${controller.selectedTopics.length} selected',
                      style: AppTextStyles.labelCaps.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...controller.topicSuggestions.map(
              (topic) => _buildTopicOption(
                topic,
                controller.selectedTopics.any((item) => item.id == topic.id),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickTopics() {
    if (_searchController.text.trim().isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TRY A TOPIC', style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _quickTopics
              .map(
                (topic) => ActionChip(
                  label: Text(topic),
                  avatar: const Icon(Icons.add, size: 14),
                  onPressed: () => _handleQuickTopic(topic),
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppColors.border, width: 1.0),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTopicDashboard() {
    return Consumer<PublicationController>(
      builder: (context, controller, child) {
        final hasData =
            controller.topicDashboardTotalWorks > 0 ||
            controller.topicDashboardPublications.isNotEmpty ||
            controller.topicDashboardTrends.isNotEmpty;

        if (controller.isLoadingTopicDashboard) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        if (controller.topicDashboardError.isNotEmpty && !hasData) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: _buildNotice(controller.topicDashboardError, Icons.error),
          );
        }

        if (!hasData) {
          return const SizedBox(height: AppSpacing.xl);
        }

        final topPublication = controller.topicDashboardTopPublication;
        final topAuthor = _firstEntry(controller.topicDashboardTopAuthors);
        final topJournal = _firstEntry(controller.topicDashboardTopJournals);

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
                    _buildMetricTile(
                      'Total publications',
                      _compactCount(controller.topicDashboardTotalWorks),
                      Icons.library_books_outlined,
                    ),
                    _buildMetricTile(
                      'Average citations',
                      controller.topicDashboardAverageCitations.toStringAsFixed(
                        1,
                      ),
                      Icons.format_quote_outlined,
                    ),
                    _buildMetricTile(
                      'Peak year',
                      controller.topicDashboardPeakYear?.toString() ?? '-',
                      Icons.timeline_outlined,
                    ),
                    _buildMetricTile(
                      'Top author',
                      topAuthor?.key ?? '-',
                      Icons.person_outline,
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
                trends: controller.topicDashboardTrends,
                forceLineChart: true,
                title: 'Publication Trend Over Time',
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  final sections = [
                    _buildRankSection(
                      'Top contributing authors',
                      controller.topicDashboardTopAuthors,
                      Icons.person_outline,
                    ),
                    _buildRankSection(
                      'Top journals',
                      controller.topicDashboardTopJournals,
                      Icons.book_outlined,
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
                _buildNotice(
                  'Leading journal: ${topJournal.key} (${_compactCount(topJournal.value)} publications)',
                  Icons.workspace_premium_outlined,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('MOST INFLUENTIAL PUBLICATIONS', style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.md),
              if (topPublication == null)
                _buildNotice('Không có dữ liệu công bố.', Icons.article)
              else
                ...controller.topicDashboardPublications
                    .take(5)
                    .map(
                      (publication) => PublicationCard(
                        title: publication.title,
                        year: publication.publicationYear.toString(),
                        journal: publication.journalName,
                        authors: publication.authorsString,
                        citations: publication.citedByCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PublicationDetailScreen(
                                publication: publication,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          Text(
            value,
            style: AppTextStyles.h2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.labelCaps,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRankSection(String title, Map<String, int> data, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.h2)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (data.isEmpty)
            Text('Không có dữ liệu.', style: AppTextStyles.bodySmall)
          else
            ...data.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _compactCount(entry.value),
                      style: AppTextStyles.labelCaps.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotice(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildTopicOption(ResearchTopic topic, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? AppColors.accentLight : AppColors.surface,
        elevation: selected ? 1 : 0,
        shadowColor: AppColors.accent.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(
            color: selected ? AppColors.accent : AppColors.border,
            width: 1,
          ),
        ),
        child: InkWell(
          key: Key('topic_option_${topic.id}'),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => _toggleTopic(topic),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected
                      ? AppColors.accent
                      : AppColors.secondary.withValues(alpha: 0.75),
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              topic.name,
                              style: AppTextStyles.bodyLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (topic.worksCount > 0) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _compactCount(topic.worksCount),
                              style: AppTextStyles.labelCaps.copyWith(
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (topic.description != null &&
                          topic.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          topic.description!,
                          style: AppTextStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  MapEntry<String, int>? _firstEntry(Map<String, int> map) {
    if (map.isEmpty) return null;
    return map.entries.first;
  }
}
