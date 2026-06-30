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
    if (userController.hasEmail) {
      _apiService = OpenAlexService(userEmail: userController.email);
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

    if (topicIds.isEmpty) {
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
                'Chưa có keyword để phân tích',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Hãy search topic ở tab HOME trước, sau đó quay lại KEYWORDS để xem phân tích keyword.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
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
              Text('KEYWORD ANALYSIS', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Based on: ${controller.currentTopic}',
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_isKeywordDashboardLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              else if (_keywordDashboardError.isNotEmpty)
                _buildKeywordNotice(_keywordDashboardError)
              else ...[
                HorizontalBarChart(
                  data: _topKeywords,
                  title: 'Most used keywords',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Counts show how often each keyword appears in journal publications for the selected research topics.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                HorizontalBarChart(
                  data: _trendingKeywords,
                  title: 'Recently active keywords',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'These keywords have the strongest activity in recent journal publications for the selected topics.',
                  style: AppTextStyles.bodySmall,
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
        _keywordDashboardError = 'Không thể tải keyword từ OpenAlex: $error';
        _isKeywordDashboardLoading = false;
      });
    }
  }

  Widget _buildKeywordFrequencyTable() {
    if (_topKeywords.isEmpty) {
      return _buildKeywordNotice('Không có dữ liệu keyword frequency.');
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KEYWORD OCCURRENCES', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.md),
          ..._topKeywords.map(
            (keyword) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () => _openKeywordDetail(keyword),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          keyword['name'].toString(),
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _compactCount((keyword['count'] as num?)?.toInt() ?? 0),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordTrendCharts() {
    if (_keywordTrends.isEmpty) {
      return _buildKeywordNotice('Không có dữ liệu xu hướng keyword.');
    }

    final keywordNamesById = {
      for (final keyword in _topKeywords)
        _keywordId(keyword['id'].toString()): keyword['name'].toString(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KEYWORD TRENDS OVER TIME', style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.md),
        ..._keywordTrends.entries.map(
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

  Widget _buildKeywordNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary, width: 1),
      ),
      child: Text(message, style: AppTextStyles.bodySmall),
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
