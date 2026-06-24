import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../utils/analysis_helper.dart';
import '../widgets/stat_card.dart';
import '../widgets/horizontal_bar_chart.dart';
import '../widgets/publication_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/year_trend_chart.dart';
import '../widgets/topic_evolution_chart.dart';
import '../widgets/author_topic_heatmap.dart';
import '../models/trend_data_model.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../services/openalex_service.dart';
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
  bool _isEvolutionLoading = false;
  List<Publication> _journalPublications = [];
  bool _isPublicationsLoading = false;
  final OpenAlexService _apiService = OpenAlexService();

  @override
  void initState() {
    super.initState();
    if (widget.journal != null) {
      _loadEvolutionData();
      _loadJournalPublications();
    }
  }

  Future<void> _loadJournalPublications() async {
    setState(() => _isPublicationsLoading = true);
    try {
      final data = await _apiService.getWorksByJournal(widget.journal!.id, perPage: 50);
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
      final data = await _apiService.getJournalTopicEvolution(widget.journal!.id);
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
        title: const Text('Research Dashboard'),
        leading: widget.journal != null && Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null, // Let Scaffold handle drawer icon if null
      ),
      drawer: (widget.journal != null && Navigator.canPop(context)) ? null : AppDrawer(currentRoute: widget.route),
      body: Consumer<PublicationController>(
        builder: (context, controller, child) {
          final publications = controller.publications;

          if (publications.isEmpty && widget.journal == null && widget.trends == null) {
            return const Center(
              child: Text('Không có dữ liệu để phân tích.'),
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

                    if (publications.isNotEmpty) ...[
                      Text(
                        'THỐNG KÊ TỔNG QUAN',
                        style: AppTextStyles.labelCaps,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildGeneralStatistics(controller, publications),
                      const SizedBox(height: AppSpacing.xl * 1.5),
                      
                      Text(
                        'TOP 5 BÀI BÁO CÓ ẢNH HƯỞNG NHẤT',
                        style: AppTextStyles.labelCaps,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildTopPapers(context, publications),
                      const SizedBox(height: AppSpacing.xl * 1.5),
                      _buildCharts(publications),
                    ],

                    const SizedBox(height: AppSpacing.xl * 2),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJournalAnalysis(BuildContext context, Journal journal) {
    // Publication Trend from real API counts_by_year
    final List<TrendData> pubTrends = journal.countsByYear
        .map((e) => TrendData(year: e.year, count: e.worksCount))
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));
      
    // Citation Trend from real API counts_by_year
    final List<TrendData> citeTrends = journal.countsByYear
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
        YearTrendChart(trends: pubTrends, forceLineChart: true, title: 'Publication Trend'),
        const SizedBox(height: AppSpacing.xl),
        YearTrendChart(trends: citeTrends, forceLineChart: true, title: 'Citation Trend'),
        const SizedBox(height: AppSpacing.xl),
        if (_isEvolutionLoading)
          const Center(child: CircularProgressIndicator())
        else if (_topicEvolution.isNotEmpty)
          TopicEvolutionChart(data: _topicEvolution)
        else
          const Center(child: Text('No topic evolution data found for this journal.')),
        
        const SizedBox(height: AppSpacing.xl),
        if (_isPublicationsLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          HorizontalBarChart(
            data: topAuthorsData,
            title: 'AUTHOR IMPACT: TÁC GIẢ CÓ NHIỀU CÔNG BỐ NHẤT',
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthorTopicHeatmap(
            publications: _journalPublications,
            title: 'AUTHOR-TOPIC MATRIX: CHUYÊN MÔN NGHIÊN CỨU CỦA TÁC GIẢ',
          ),
        ],
      ],
    );
  }

  Widget _buildGeneralStatistics(PublicationController controller, List<Publication> publications) {
    final totalPublications = controller.totalResults > 0 
        ? controller.totalResults.toString() 
        : publications.length.toString();
    
    final totalCitations = controller.totalCitationsGlobal > 0
        ? controller.totalCitationsGlobal.toString()
        : AnalysisHelper.getTotalCitations(publications).toString();
        
    final avgCitations = (double.parse(totalCitations) / double.parse(totalPublications)).toStringAsFixed(1);

    final mostActiveYear = 
        AnalysisHelper.getMostActivePublicationYear(publications)?.toString() ?? 'N/A';

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: constraints.maxWidth >= 600 ? 1.5 : 1.2,
          children: [
            StatCard(title: 'Tổng bài báo', value: totalPublications, icon: Icons.article_outlined),
            StatCard(title: 'Tổng trích dẫn', value: totalCitations, icon: Icons.format_quote),
            StatCard(title: 'Trích dẫn TB', value: avgCitations, icon: Icons.analytics_outlined),
            StatCard(title: 'Năm tích cực', value: mostActiveYear, icon: Icons.calendar_today_outlined),
          ],
        );
      },
    );
  }

  Widget _buildTopPapers(BuildContext context, List<Publication> publications) {
    final topPapers = AnalysisHelper.getTopCitedPapers(publications, limit: 5);
    return Column(
      children: topPapers.map((pub) => PublicationCard(
        title: pub.title,
        year: pub.publicationYear.toString(),
        journal: pub.journalName,
        authors: pub.authorsString,
        citations: pub.citedByCount,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicationDetailScreen(publication: pub),
            ),
          );
        },
      )).toList(),
    );
  }

  Widget _buildCharts(List<Publication> publications) {
    final topJournals = AnalysisHelper.getTopJournals(publications);
    final topAuthors = AnalysisHelper.getTopAuthors(publications);
    
    final journalData = topJournals.entries.map((e) => {'name': e.key, 'count': e.value}).toList();
    final authorData = topAuthors.entries.map((e) => {'name': e.key, 'count': e.value}).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HorizontalBarChart(data: journalData, title: 'TOP 5 TẠP CHÍ PHỔ BIẾN'),
              const SizedBox(height: AppSpacing.xl),
              HorizontalBarChart(data: authorData, title: 'TOP 5 TÁC GIẢ ĐÓNG GÓP'),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: HorizontalBarChart(data: journalData, title: 'TOP 5 TẠP CHÍ PHỔ BIẾN')),
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: HorizontalBarChart(data: authorData, title: 'TOP 5 TÁC GIẢ ĐÓNG GÓP')),
            ],
          );
        }
      },
    );
  }
}
