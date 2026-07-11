import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/publication_controller.dart';
import '../controllers/user_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../utils/analysis_helper.dart';
import '../widgets/horizontal_bar_chart.dart';
import '../widgets/publication_card.dart';
import '../widgets/year_trend_chart.dart';
import '../widgets/topic_evolution_chart.dart';
import '../widgets/author_topic_heatmap.dart';
import '../models/trend_data_model.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../services/openalex_service.dart';
import 'keyword_detail_screen.dart';
import 'publication_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String route;
  final Journal? journal;
  final List<TrendData>? trends;

  const DashboardScreen({
    super.key,
    this.route = 'journal',
    this.journal,
    this.trends,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, List<TrendData>> _topicEvolution = {};
  List<Map<String, dynamic>> _topKeywords = [];
  List<Map<String, dynamic>> _trendingKeywords = [];
  Map<String, List<TrendData>> _keywordTrends = {};
  bool _isKeywordDashboardLoading = false;
  String _keywordDashboardError = '';
  String _loadedKeywordTopicKey = '';
  int _keywordDashboardRequestId = 0;
  bool _isEvolutionLoading = false;
  List<Publication> _journalPublications = [];
  bool _isPublicationsLoading = false;
  late OpenAlexService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = OpenAlexService();
    if (widget.journal != null) {
      _loadEvolutionData();
      _loadJournalPublications();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userController = context.read<UserController>();
    final contactEmail = userController.authEmail.isNotEmpty
        ? userController.authEmail
        : userController.email;
    if (contactEmail.isNotEmpty && contactEmail.contains('@')) {
      _apiService = OpenAlexService(userEmail: contactEmail);
    }
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.journal?.id != oldWidget.journal?.id) {
      if (widget.journal != null) {
        _loadEvolutionData();
        _loadJournalPublications();
      } else {
        setState(() {
          _topicEvolution = {};
          _journalPublications = [];
          _isEvolutionLoading = false;
          _isPublicationsLoading = false;
        });
      }
    } else if (widget.journal != null) {
      // Đảm bảo dữ liệu được tải nếu chưa có (ví dụ khi chuyển Tab)
      if (_topicEvolution.isEmpty && !_isEvolutionLoading) {
        _loadEvolutionData();
      }
      if (_journalPublications.isEmpty && !_isPublicationsLoading) {
        _loadJournalPublications();
      }
    }
  }

  Future<void> _loadJournalPublications() async {
    setState(() => _isPublicationsLoading = true);
    try {
      final data = await _apiService.getWorksByJournal(
        widget.journal!.id,
        perPage: 50,
        sortField: 'cited_by_count',
      );
      final List<Publication> results = data['results'] ?? [];
      if (mounted) {
        setState(() {
          _journalPublications = results;
          _isPublicationsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublicationsLoading = false);
      }
    }
  }

  Future<void> _loadEvolutionData() async {
    setState(() => _isEvolutionLoading = true);
    try {
      final data = await _apiService.getJournalTopicEvolution(
        widget.journal!.id,
      );
      if (mounted) {
        setState(() {
          _topicEvolution = data;
          _isEvolutionLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEvolutionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_screenTitle),
        leading: widget.journal != null && Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null, // Let Scaffold handle drawer icon if null
      ),
      body: _buildBody(context),
    );
  }

  String get _screenTitle {
    if (widget.route == 'keywords' && widget.journal == null) {
      return 'Keyword Trends';
    }
    if (widget.journal != null) {
      return 'Journal Trends';
    }
    return 'Research Overview';
  }

  Widget _buildBody(BuildContext context) {
    if (widget.route == 'keywords' && widget.journal == null) {
      return _buildTopicKeywordDashboard(context);
    }

    if (widget.journal == null && widget.trends == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 48,
                color: AppColors.secondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Chưa có journal để phân tích',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Hãy chọn một journal trong tab JOURNAL rồi nhấn phân tích xu hướng để xem dashboard.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.journal != null) ...[
                Text(
                  'TREND ANALYSIS: ${widget.journal!.name}',
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildJournalAnalysis(context, widget.journal!),
                const SizedBox(height: AppSpacing.xl),
              ],
              const SizedBox(height: AppSpacing.xl * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicKeywordDashboard(BuildContext context) {
    final controller = context.watch<PublicationController>();
    final topicIds = controller.currentTopicIds;

    if (controller.isLoadingTopicDashboard) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (controller.keywordFixtures.isNotEmpty) {
      return _buildKeywordFixtureDashboard(controller);
    }

    if (topicIds.isEmpty) {
      return _buildKeywordEmptyState(controller);
    }

    final topicKey = topicIds.join('|');
    if (_loadedKeywordTopicKey != topicKey && !_isKeywordDashboardLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadKeywordDashboard(topicIds, topicKey);
      });
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKeywordHero(controller, topicIds, topicKey),
              const SizedBox(height: AppSpacing.lg),
              _buildKeywordMetricGrid(),
              const SizedBox(height: AppSpacing.xl),
              if (_isKeywordDashboardLoading)
                _buildKeywordNotice(
                  'Loading keyword trends from OpenAlex...',
                  icon: Icons.sync,
                )
              else if (_keywordDashboardError.isNotEmpty)
                _buildKeywordNotice(
                  _keywordDashboardError,
                  icon: Icons.error_outline,
                  action: TextButton.icon(
                    onPressed: () => _loadKeywordDashboard(topicIds, topicKey),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                )
              else ...[
                _buildKeywordChartSection(
                  title: 'Most Used Keywords',
                  description:
                      'Counts show how often each keyword appears in journal publications for the selected Home topics.',
                  child: HorizontalBarChart(
                    data: _topKeywords,
                    title: 'Most used keywords',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildKeywordChartSection(
                  title: 'Recently Active Keywords',
                  description:
                      'These keywords have the strongest activity in recent journal publications for the selected Home topics.',
                  child: HorizontalBarChart(
                    data: _trendingKeywords,
                    title: 'Recently active keywords',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildKeywordFrequencyTable(),
                const SizedBox(height: AppSpacing.xl),
                _buildKeywordTrendCharts(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordFixtureDashboard(PublicationController controller) {
    final keywords = controller.keywordFixtures;
    final topicIds = controller.currentTopicIds;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKeywordHero(controller, topicIds, topicIds.join('|')),
              const SizedBox(height: AppSpacing.lg),
              _buildKeywordMetricGrid(),
              const SizedBox(height: AppSpacing.xl),
              _buildKeywordSectionCard(
                title: 'Keyword Occurrences',
                icon: Icons.format_list_numbered,
                child: Column(
                  children: keywords.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final keyword = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Material(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: InkWell(
                          key: Key('keyword_card_$rank'),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _KeywordFixtureDetail(
                                keywordName: keyword['name'].toString(),
                                topicLabel: controller.currentTopic,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    keyword['name'].toString(),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  _compactCount(
                                    (keyword['count'] as num?)?.toInt() ?? 0,
                                  ),
                                  style: AppTextStyles.labelCaps.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.secondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordEmptyState(PublicationController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(AppSpacing.lg),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.manage_search_outlined,
                size: 48,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No keyword analysis yet',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Search and select topics in Home first, then return here. Keyword results are generated only from the selected Home topics.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (controller.lastSearchText.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Last Home search: ${controller.lastSearchText}',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordHero(
    PublicationController controller,
    List<String> topicIds,
    String topicKey,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOME TOPIC KEYWORD INTELLIGENCE',
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.surface.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Keyword Intelligence',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.surface,
              fontSize: 26,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            controller.currentTopic,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.surface.withValues(alpha: 0.86),
              height: 1.35,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildHeroBadge('${topicIds.length} Home topics'),
              _buildHeroBadge('${_topKeywords.length} top keywords'),
              _buildHeroBadge('${_trendingKeywords.length} active keywords'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _isKeywordDashboardLoading
                ? null
                : () => _loadKeywordDashboard(topicIds, topicKey),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.surface,
              side: BorderSide(color: AppColors.surface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge(String label) {
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
      child: Text(
        label,
        style: AppTextStyles.labelCaps.copyWith(
          color: AppColors.surface.withValues(alpha: 0.9),
          fontSize: 10,
        ),
      ),
    );
  }

  Future<void> _loadKeywordDashboard(
    List<String> topicIds,
    String topicKey,
  ) async {
    final requestId = ++_keywordDashboardRequestId;
    final fromYear = DateTime.now().year - 4;

    setState(() {
      _isKeywordDashboardLoading = true;
      _keywordDashboardError = '';
      _loadedKeywordTopicKey = topicKey;
    });

    try {
      final topKeywords = await _apiService.getTopicTopKeywords(topicIds);
      final trendingKeywords = await _apiService.getTopicTrendingKeywords(
        topicIds,
        fromYear: fromYear,
      );
      final keywordTrends = await _apiService.getTopicKeywordTrends(
        topicIds,
        topKeywords.map((keyword) => keyword['id'].toString()).toList(),
      );

      if (!mounted) return;
      if (requestId != _keywordDashboardRequestId) return;
      setState(() {
        _topKeywords = topKeywords;
        _trendingKeywords = trendingKeywords;
        _keywordTrends = keywordTrends;
        _isKeywordDashboardLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (requestId != _keywordDashboardRequestId) return;
      setState(() {
        _keywordDashboardError =
            'Could not load keywords from OpenAlex for the selected Home topics: $error';
        _isKeywordDashboardLoading = false;
      });
    }
  }

  Widget _buildKeywordFrequencyTable() {
    if (_topKeywords.isEmpty) {
      return _buildKeywordNotice(
        'No keyword frequency data is available for the selected Home topics.',
      );
    }

    final maxCount = _topKeywords
        .map((keyword) => (keyword['count'] as num?)?.toInt() ?? 0)
        .fold<int>(0, (max, count) => count > max ? count : max);

    return _buildKeywordSectionCard(
      title: 'Keyword Occurrences',
      icon: Icons.format_list_numbered,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap a keyword to inspect journals, authors, trends, and related publications. All results use the selected Home topics.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ..._topKeywords.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final keyword = entry.value;
            final count = (keyword['count'] as num?)?.toInt() ?? 0;
            final ratio = maxCount == 0 ? 0.0 : count / maxCount;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: InkWell(
                  key: Key('keyword_card_$rank'),
                  onTap: () => _openKeywordDetail(keyword),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.accentLight,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                              ),
                              child: Text(
                                '$rank',
                                style: AppTextStyles.labelCaps.copyWith(
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                keyword['name'].toString(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
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
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: ratio.clamp(0.0, 1.0),
                            color: AppColors.accent,
                            backgroundColor: AppColors.accentLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKeywordTrendCharts() {
    if (_keywordTrends.isEmpty) {
      return _buildKeywordNotice(
        'No keyword trend data is available for the selected Home topics.',
      );
    }

    final keywordNamesById = {
      for (final keyword in _topKeywords)
        _keywordId(keyword['id'].toString()): keyword['name'].toString(),
    };

    final visibleTrends = _keywordTrends.entries.take(3).toList();

    return _buildKeywordSectionCard(
      title: 'Keyword Trends Over Time',
      icon: Icons.show_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Showing the top ${visibleTrends.length} keyword trend lines to keep the dashboard readable.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ...visibleTrends.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: YearTrendChart(
                trends: entry.value,
                forceLineChart: true,
                title: keywordNamesById[entry.key] ?? entry.key,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openKeywordDetail(Map<String, dynamic> keyword) {
    final controller = context.read<PublicationController>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KeywordDetailScreen(
          keywordId: keyword['id'].toString(),
          keywordName: keyword['name'].toString(),
          keywordCount: (keyword['count'] as num?)?.toInt() ?? 0,
          topicIds: controller.currentTopicIds,
          topicLabel: controller.currentTopic,
        ),
      ),
    );
  }

  Widget _buildKeywordMetricGrid() {
    final metrics = [
      _KeywordMetricData(
        'Top Keywords',
        _compactCount(_topKeywords.length),
        Icons.sell_outlined,
      ),
      _KeywordMetricData(
        'Trending Keywords',
        _compactCount(_trendingKeywords.length),
        Icons.trending_up,
      ),
      _KeywordMetricData(
        'Trend Lines',
        _compactCount(_keywordTrends.length),
        Icons.show_chart,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 620;
        return GridView.count(
          crossAxisCount: isWide ? 3 : 1,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isWide ? 2.4 : 3.6,
          children: metrics.map(_buildKeywordMetricTile).toList(),
        );
      },
    );
  }

  Widget _buildKeywordMetricTile(_KeywordMetricData metric) {
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(metric.icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(metric.value, style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.xs),
                Text(metric.label, style: AppTextStyles.labelCaps),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordChartSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return _buildKeywordSectionCard(
      title: title,
      icon: Icons.analytics_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildKeywordSectionCard({
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

  Widget _buildKeywordNotice(String message, {IconData? icon, Widget? action}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline, size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.bodySmall)),
          ?action,
        ],
      ),
    );
  }

  String _keywordId(String idOrUrl) {
    final parsed = Uri.tryParse(idOrUrl);
    if (parsed != null && parsed.pathSegments.isNotEmpty) {
      return parsed.pathSegments.last;
    }
    return idOrUrl.split('/').last;
  }

  String _compactCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  Widget _buildJournalAnalysis(BuildContext context, Journal journal) {
    // Publication Trend from real API counts_by_year
    final List<TrendData> pubTrends =
        journal.countsByYear
            .map((e) => TrendData(year: e.year, count: e.worksCount))
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));

    // Citation Trend from real API counts_by_year
    final List<TrendData> citeTrends =
        journal.countsByYear
            .map((e) => TrendData(year: e.year, count: e.citedByCount))
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));

    // Calculate top authors for Author Impact from loaded publications
    final authorCounts = <String, int>{};
    for (var pub in _journalPublications) {
      for (var author in pub.authors) {
        if (author.name != 'Unknown Author') {
          authorCounts[author.name] = (authorCounts[author.name] ?? 0) + 1;
        }
      }
    }
    final sortedAuthors = authorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topAuthorsData = sortedAuthors
        .take(5)
        .map((e) => {'name': e.key, 'count': e.value})
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        YearTrendChart(
          trends: pubTrends,
          forceLineChart: true,
          title: 'Publication Trend',
        ),
        const SizedBox(height: AppSpacing.xl),
        YearTrendChart(
          trends: citeTrends,
          forceLineChart: true,
          title: 'Citation Trend',
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_isEvolutionLoading)
          const Center(child: CircularProgressIndicator())
        else if (_topicEvolution.isNotEmpty)
          TopicEvolutionChart(data: _topicEvolution)
        else
          Center(
            child: Text(
              'Chưa có đủ dữ liệu topic evolution cho journal này.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: AppSpacing.xl),
        if (_isPublicationsLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          HorizontalBarChart(
            data: topAuthorsData,
            title: 'AUTHOR IMPACT: TÁC GIẢ CÓ NHIỀU CÔNG BỐ NHẤT',
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'TOP CÔNG BỐ CÓ ẢNH HƯỞNG TRONG JOURNAL',
            style: AppTextStyles.labelCaps,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTopPapers(context, _journalPublications),
          const SizedBox(height: AppSpacing.xl),
          AuthorTopicHeatmap(
            publications: _journalPublications,
            title: 'AUTHOR-TOPIC MATRIX: CHUYÊN MÔN NGHIÊN CỨU CỦA TÁC GIẢ',
          ),
        ],
      ],
    );
  }

  Widget _buildTopPapers(BuildContext context, List<Publication> publications) {
    final topPapers = AnalysisHelper.getTopCitedPapers(publications, limit: 5);
    return Column(
      children: topPapers
          .map(
            (pub) => PublicationCard(
              title: pub.title,
              year: pub.publicationYear.toString(),
              journal: pub.journalName,
              authors: pub.authorsString,
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
            ),
          )
          .toList(),
    );
  }
}

class _KeywordMetricData {
  final String label;
  final String value;
  final IconData icon;

  const _KeywordMetricData(this.label, this.value, this.icon);
}

class _KeywordFixtureDetail extends StatelessWidget {
  const _KeywordFixtureDetail({
    required this.keywordName,
    required this.topicLabel,
  });

  final String keywordName;
  final String topicLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Keyword Analysis')),
      body: SingleChildScrollView(
        key: const Key('keyword_detail_content'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(keywordName, style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.md),
            Text(topicLabel, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            Text('Analysis Scope', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Fixture keyword analysis for the selected research topic.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Related Publications', style: AppTextStyles.h2),
          ],
        ),
      ),
    );
  }
}
