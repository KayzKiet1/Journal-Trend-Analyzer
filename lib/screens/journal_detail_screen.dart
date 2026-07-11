import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../models/trend_data_model.dart';
import '../controllers/journal_library_controller.dart';
import '../firebase/firebase_analytics_service.dart';
import '../services/openalex_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/horizontal_bar_chart.dart';
import '../widgets/journal_impact_charts.dart';
import '../widgets/publication_card.dart';
import '../widgets/year_trend_chart.dart';
import '../widgets/loading_widget.dart';
import 'publication_detail_screen.dart';

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
  bool _isLoading = true;
  Journal? _journal;
  List<Publication> _works = [];
  List<TrendData> _trends = [];
  List<TrendData> _citationTrends = [];
  List<Map<String, dynamic>> _topTopics = [];
  List<Map<String, dynamic>> _topAuthors = [];
  int _currentPage = 1;
  int _totalWorks = 0;
  bool _isWorksLoading = false;
  final int _perPage = 10;
  final ScrollController _scrollController = ScrollController();
  final OpenAlexService _apiService = OpenAlexService();
  final FirebaseAnalyticsService _analyticsService = FirebaseAnalyticsService();

  // Filter and Search states
  final TextEditingController _searchController = TextEditingController();
  int? _selectedYear;
  int? _minCitations;
  final List<int> _citationOptions = [0, 10, 50, 100, 500, 1000];

  // Sorting states
  String _sortField = 'publication_year';
  bool _isDescending = true;

  @override
  void initState() {
    super.initState();
    _analyticsService.logViewJournal(journalName: widget.journalName);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (widget.journalForTesting != null) {
      setState(() {
        _journal = widget.journalForTesting;
        _works = [];
        _totalWorks = widget.journalForTesting!.worksCount;
        _trends = widget.journalForTesting!.countsByYear
            .map((item) => TrendData(year: item.year, count: item.worksCount))
            .toList();
        _citationTrends = _buildCitationTrends(widget.journalForTesting!);
        _topTopics = [
          {'name': 'Artificial Intelligence', 'count': 42},
          {'name': 'Machine Learning', 'count': 28},
        ];
        _topAuthors = [
          {'name': 'Ada Lovelace', 'count': 8},
          {'name': 'Alan Turing', 'count': 6},
        ];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getJournalDetails(widget.journalId),
        _apiService.getWorksByJournal(
          widget.journalId,
          page: 1,
          topicIds: widget.topicIds,
        ),
        _apiService.getJournalYearlyTrend(
          widget.journalId,
          topicIds: widget.topicIds,
        ),
        _apiService.getJournalTopTopics(widget.journalId),
        _apiService.getJournalTopAuthors(
          widget.journalId,
          topicIds: widget.topicIds,
        ),
      ]);

      setState(() {
        _journal = results[0] as Journal;
        final worksData = results[1] as Map<String, dynamic>;
        _works = worksData['results'];
        _totalWorks = worksData['total_count'];
        _trends = results[2] as List<TrendData>;
        _topTopics = results[3] as List<Map<String, dynamic>>;
        _topAuthors = results[4] as List<Map<String, dynamic>>;
        _citationTrends = _buildCitationTrends(_journal!);
        _isLoading = false;
      });
      if (mounted && _journal != null) {
        context.read<JournalLibraryController>().addRecentViewed(_journal!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not load journal: $e')));
      }
    }
  }

  Future<void> _goToPage(int page) async {
    if (page < 1 || (page - 1) * _perPage >= _totalWorks) return;

    setState(() {
      _isWorksLoading = true;
      _currentPage = page;
    });

    try {
      final worksData = await _apiService.getWorksByJournal(
        widget.journalId,
        page: _currentPage,
        topicIds: widget.topicIds,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        year: _selectedYear,
        minCitations: _minCitations,
        sortField: _sortField,
        descending: _isDescending,
      );
      setState(() {
        _works = worksData['results'];
        _totalWorks = worksData['total_count'];
        _isWorksLoading = false;
      });
      // Scroll back up to the start of the works list
      // Note: In a SingleChildScrollView, we might need a more complex logic if we want to scroll to a specific widget
    } catch (e) {
      setState(() => _isWorksLoading = false);
    }
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
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(
          message: 'Loading journal profile from OpenAlex...',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _journal?.name ?? widget.journalName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
        actions: [
          if (_journal != null)
            Consumer<JournalLibraryController>(
              builder: (context, library, child) {
                final isFavorite = library.isFavorite(_journal!.id);
                return IconButton(
                  tooltip: isFavorite ? 'Remove from library' : 'Save journal',
                  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                  onPressed: () => library.toggleFavorite(_journal!),
                );
              },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                if (widget.topicLabel != null &&
                    widget.topicLabel!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildHomeTopicScope(),
                ],
                const SizedBox(height: AppSpacing.lg),

                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isDesktop = constraints.maxWidth > 700;
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                YearTrendChart(
                                  trends: _trends,
                                  title: 'Publication Trend',
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                YearTrendChart(
                                  trends: _citationTrends,
                                  forceLineChart: true,
                                  title: 'Citation Trend',
                                  valueLabel: 'citations',
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                PublicationCitationTrendChart(
                                  yearlyData:
                                      _journal?.countsByYear ?? const [],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                CitationsPerPublicationChart(
                                  yearlyData:
                                      _journal?.countsByYear ?? const [],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                HorizontalBarChart(
                                  data: _topAuthors,
                                  title: 'Top Authors by Publications',
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _buildWorksList(),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                _buildStatsCard(),
                                const SizedBox(height: AppSpacing.lg),
                                _buildTopicList(),
                                const SizedBox(height: AppSpacing.lg),
                                _buildInfoCard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildStatsCard(),
                          const SizedBox(height: AppSpacing.lg),
                          YearTrendChart(
                            trends: _trends,
                            title: 'Publication Trend',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          YearTrendChart(
                            trends: _citationTrends,
                            forceLineChart: true,
                            title: 'Citation Trend',
                            valueLabel: 'citations',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          PublicationCitationTrendChart(
                            yearlyData: _journal?.countsByYear ?? const [],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          CitationsPerPublicationChart(
                            yearlyData: _journal?.countsByYear ?? const [],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildTopicList(),
                          const SizedBox(height: AppSpacing.lg),
                          HorizontalBarChart(
                            data: _topAuthors,
                            title: 'Top Authors by Publications',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildWorksList(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildInfoCard(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return _buildSectionCard(
      title: 'Journal Metadata',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IDENTITY', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow('Publisher', _journal?.publisher),
          _buildInfoRow('Source type', _journal?.type),
          _buildInfoRow('ISSNs', _journal?.issns.join(', ')),
          _buildInfoRow('Alternate names', _journal?.alternateNames.join(', ')),
          const Divider(height: AppSpacing.xl),
          Text('ACCESS', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow('Homepage', _journal?.homepageUrl, isLink: true),
          _buildInfoRow('Fully open access', _yesNo(_journal?.isOa)),
          _buildInfoRow('Indexed in DOAJ', _yesNo(_journal?.isInDoaj)),
          _buildInfoRow(
            'Article processing charge',
            _journal?.apcUsd != null ? '\$${_journal!.apcUsd}' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final journal = _journal;
    final sourceType = journal?.type?.trim().isNotEmpty == true
        ? journal!.type!.toUpperCase()
        : 'JOURNAL';

    return Consumer<JournalLibraryController>(
      builder: (context, library, child) {
        final isFavorite = journal != null && library.isFavorite(journal.id);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            gradient: const LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primarySoft,
                AppColors.accent,
              ],
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _buildHeaderBadge(sourceType, Icons.book_outlined),
                  if (journal?.isOa == true)
                    _buildHeaderBadge('OPEN ACCESS', Icons.lock_open),
                  if (journal?.isInDoaj == true)
                    _buildHeaderBadge('DOAJ', Icons.verified_outlined),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                journal?.name ?? widget.journalName,
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.surface,
                  fontSize: 26,
                  height: 1.15,
                ),
              ),
              if (journal?.publisher?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  journal!.publisher!,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.86),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: journal == null
                        ? null
                        : () => library.toggleFavorite(journal),
                    icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                    label: Text(isFavorite ? 'Saved' : 'Save Journal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.surface,
                      side: BorderSide(
                        color: AppColors.surface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  if (journal?.homepageUrl?.isNotEmpty == true)
                    OutlinedButton.icon(
                      onPressed: () => _launchUrl(journal!.homepageUrl),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Homepage'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.surface,
                        side: BorderSide(
                          color: AppColors.surface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.surface),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.surface.withValues(alpha: 0.9),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {bool isLink = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: isLink ? () => _launchUrl(value) : null,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isLink ? AppColors.accent : AppColors.primary,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final metrics = [
      _MetricData(
        'Publications',
        _compactCount(_journal?.worksCount ?? 0),
        Icons.article_outlined,
      ),
      _MetricData(
        'Citations',
        _compactCount(_journal?.citedByCount ?? 0),
        Icons.format_quote,
      ),
      _MetricData('H-index', _journal?.hIndex?.toString() ?? '-', Icons.tag),
      _MetricData(
        'I10-index',
        _journal?.i10Index?.toString() ?? '-',
        Icons.format_list_numbered,
      ),
      _MetricData(
        '2yr citedness',
        _journal?.twoYearMeanCitedness?.toStringAsFixed(3) ?? '-',
        Icons.trending_up,
      ),
    ];

    return _buildSectionCard(
      title: 'Key Metrics',
      icon: Icons.analytics_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 420;
              return GridView.count(
                crossAxisCount: isWide ? 3 : 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 1.45 : 1.35,
                children: metrics
                    .map(
                      (metric) => _buildMetricTile(
                        metric.label,
                        metric.value,
                        metric.icon,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'H-index and I10-index are calculated for this source from OpenAlex works. 2yr citedness is a source-level citation average.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(color: AppColors.accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.labelCaps,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<TrendData> _buildCitationTrends(Journal journal) {
    final trends = journal.countsByYear
        .where((data) => data.year > 0 && data.citedByCount > 0)
        .map((data) => TrendData(year: data.year, count: data.citedByCount))
        .toList();
    trends.sort((a, b) => a.year.compareTo(b.year));
    return trends;
  }

  Widget _buildTopicList() {
    if (_topTopics.isEmpty) return const SizedBox.shrink();

    final maxCount = _topTopics
        .map((topic) => (topic['count'] as num?)?.toInt() ?? 0)
        .fold<int>(0, (max, count) => count > max ? count : max);

    return _buildSectionCard(
      title: 'Top Topics',
      icon: Icons.sell_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._topTopics.map((topic) {
            final count = (topic['count'] as num?)?.toInt() ?? 0;
            final ratio = maxCount == 0 ? 0.0 : count / maxCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic['name']?.toString() ?? 'Unknown topic',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _compactCount(count),
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: ratio.clamp(0.0, 1.0),
                      color: AppColors.accent,
                      backgroundColor: AppColors.accentLight,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _topTopics.take(4).map((topic) {
              return Chip(
                label: Text(topic['name']?.toString() ?? 'Topic'),
                backgroundColor: AppColors.surfaceTint,
                labelStyle: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                ),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
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
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.h2)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  String _yesNo(bool? value) {
    if (value == null) return 'Unknown';
    return value ? 'Yes' : 'No';
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

  Future<void> _resetFilters() async {
    setState(() {
      _searchController.clear();
      _selectedYear = null;
      _minCitations = null;
      _sortField = 'publication_year';
      _isDescending = true;
    });
    await _applyFilters();
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isWorksLoading = true;
      _currentPage = 1;
    });

    try {
      final worksData = await _apiService.getWorksByJournal(
        widget.journalId,
        page: _currentPage,
        topicIds: widget.topicIds,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        year: _selectedYear,
        minCitations: _minCitations,
        sortField: _sortField,
        descending: _isDescending,
      );
      setState(() {
        _works = worksData['results'];
        _totalWorks = worksData['total_count'];
        _isWorksLoading = false;
      });
    } catch (e) {
      setState(() => _isWorksLoading = false);
    }
  }

  Widget _buildHomeTopicScope() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        'Research scope: ${widget.topicLabel}',
        style: AppTextStyles.bodySmall,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildWorksList() {
    int totalPages = (_totalWorks / _perPage).ceil();
    if (totalPages == 0 && _totalWorks > 0) totalPages = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RECENT PUBLICATIONS', style: AppTextStyles.labelCaps),
            if (_totalWorks > 0)
              Text(
                '$_totalWorks publications',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFilterBar(),
        const SizedBox(height: AppSpacing.md),
        if (_isWorksLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _works.length,
            itemBuilder: (context, index) {
              final pub = _works[index];
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
          ),
        if (totalPages > 1) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildPaginationBar(totalPages),
        ],
      ],
    );
  }

  Widget _buildFilterBar() {
    List<int> availableYears = _trends.map((t) => t.year).toSet().toList();
    availableYears.sort((a, b) => b.compareTo(a));

    return _buildSectionCard(
      title: 'Search & Filter',
      icon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            style: AppTextStyles.bodySmall,
            decoration: InputDecoration(
              hintText: 'Search publication titles...',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppColors.secondary,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        setState(_searchController.clear);
                        _applyFilters();
                      },
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Clear publication search',
                    ),
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceTint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _applyFilters(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildLabeledDropdown<int?>(
                  label: 'PUBLICATION YEAR',
                  value: _selectedYear,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All years', style: TextStyle(fontSize: 12)),
                    ),
                    ...availableYears.map(
                      (y) => DropdownMenuItem(
                        value: y,
                        child: Text(
                          y.toString(),
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedYear = val);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildLabeledDropdown<int?>(
                  label: 'MIN CITATIONS',
                  value: _minCitations,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Any', style: TextStyle(fontSize: 12)),
                    ),
                    ..._citationOptions
                        .where((opt) => opt > 0)
                        .map(
                          (opt) => DropdownMenuItem(
                            value: opt,
                            child: Text(
                              '$opt+',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                  ],
                  onChanged: (val) {
                    setState(() => _minCitations = val);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildLabeledDropdown<String>(
                  label: 'SORT BY',
                  value: _sortField,
                  items: const [
                    DropdownMenuItem(
                      value: 'publication_year',
                      child: Text(
                        'Publication year',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'cited_by_count',
                      child: Text('Citations', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _sortField = val);
                      _applyFilters();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildLabeledDropdown<bool>(
                  label: 'ORDER',
                  value: _isDescending,
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text('Descending', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Ascending', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _isDescending = val);
                      _applyFilters();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Reset filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelCaps.copyWith(
            fontSize: 9,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.secondary,
              ),
              items: items,
              onChanged: onChanged,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationBar(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: _currentPage > 1
                ? () => _goToPage(_currentPage - 1)
                : null,
            color: AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Page $_currentPage of $totalPages',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: _currentPage < totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;

  const _MetricData(this.label, this.value, this.icon);
}
