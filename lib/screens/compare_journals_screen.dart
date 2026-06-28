import 'package:flutter/material.dart';
import '../models/journal_model.dart';
import '../models/trend_data_model.dart';
import '../services/openalex_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/year_trend_chart.dart';

class CompareJournalsScreen extends StatefulWidget {
  final List<Journal> journals;

  const CompareJournalsScreen({super.key, required this.journals});

  @override
  State<CompareJournalsScreen> createState() => _CompareJournalsScreenState();
}

class _CompareJournalsScreenState extends State<CompareJournalsScreen> {
  final OpenAlexService _apiService = OpenAlexService();
  final List<Journal> _details = [];
  final Map<String, List<Map<String, dynamic>>> _topicsByJournal = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadComparisonData();
  }

  Future<void> _loadComparisonData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final details = <Journal>[];
      final topicsByJournal = <String, List<Map<String, dynamic>>>{};

      // Load tuần tự để request rõ ràng và thân thiện với rate limit OpenAlex.
      for (final journal in widget.journals.take(2)) {
        final detail = await _apiService.getJournalDetails(journal.id);
        final topics = await _apiService.getJournalTopTopics(journal.id);
        details.add(detail);
        topicsByJournal[detail.id] = topics;
      }

      if (!mounted) return;
      setState(() {
        _details
          ..clear()
          ..addAll(details);
        _topicsByJournal
          ..clear()
          ..addAll(topicsByJournal);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu so sánh: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Compare Journals')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(_errorMessage, style: AppTextStyles.bodyMedium),
        ),
      );
    }

    if (_details.length < 2) {
      return const Center(child: Text('Cần chọn 2 journal để so sánh.'));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TỔNG QUAN SO SÁNH', style: AppTextStyles.labelCaps),
              const SizedBox(height: AppSpacing.md),
              _buildSummaryTable(),
              const SizedBox(height: AppSpacing.xl),
              _buildTrendSection(
                title: 'PUBLICATION TREND',
                trendsBuilder: _publicationTrends,
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildTrendSection(
                title: 'CITATION TREND',
                trendsBuilder: _citationTrends,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('TOP TOPICS', style: AppTextStyles.labelCaps),
              const SizedBox(height: AppSpacing.md),
              _buildTopicComparison(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTable() {
    final left = _details[0];
    final right = _details[1];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary, width: 1),
      ),
      child: Column(
        children: [
          _buildMetricRow('Journal', left.name, right.name, isHeader: true),
          _buildMetricRow(
            'Publisher',
            left.publisher ?? '-',
            right.publisher ?? '-',
          ),
          _buildMetricRow('Works', '${left.worksCount}', '${right.worksCount}'),
          _buildMetricRow(
            'Citations',
            '${left.citedByCount}',
            '${right.citedByCount}',
          ),
          _buildMetricRow(
            'Avg citations/work',
            _avgCitations(left),
            _avgCitations(right),
          ),
          _buildMetricRow(
            'H-index',
            left.hIndex?.toString() ?? '-',
            right.hIndex?.toString() ?? '-',
          ),
          _buildMetricRow(
            'I10-index',
            left.i10Index?.toString() ?? '-',
            right.i10Index?.toString() ?? '-',
          ),
          _buildMetricRow(
            '2yr mean citedness',
            left.twoYearMeanCitedness?.toStringAsFixed(3) ?? '-',
            right.twoYearMeanCitedness?.toStringAsFixed(3) ?? '-',
          ),
          _buildMetricRow(
            'Open access',
            left.isOa ? 'Yes' : 'No',
            right.isOa ? 'Yes' : 'No',
          ),
          _buildMetricRow(
            'In DOAJ',
            left.isInDoaj ? 'Yes' : 'No',
            right.isInDoaj ? 'Yes' : 'No',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String left,
    String right, {
    bool isHeader = false,
  }) {
    final textStyle = isHeader
        ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)
        : AppTextStyles.bodySmall;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.secondary.withValues(alpha: 0.18),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
            ),
          ),
          Expanded(flex: 4, child: Text(left, style: textStyle)),
          const SizedBox(width: AppSpacing.md),
          Expanded(flex: 4, child: Text(right, style: textStyle)),
        ],
      ),
    );
  }

  Widget _buildTrendSection({
    required String title,
    required List<TrendData> Function(Journal journal) trendsBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final charts = _details.map((journal) {
              return YearTrendChart(
                trends: trendsBuilder(journal),
                forceLineChart: true,
                title: journal.name,
              );
            }).toList();

            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  charts[0],
                  const SizedBox(height: AppSpacing.md),
                  charts[1],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: charts[0]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: charts[1]),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopicComparison() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = _details.map((journal) {
          final topics = _topicsByJournal[journal.id] ?? [];
          return _buildTopicCard(journal.name, topics);
        }).toList();

        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: AppSpacing.md),
              cards[1],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }

  Widget _buildTopicCard(
    String journalName,
    List<Map<String, dynamic>> topics,
  ) {
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
          Text(journalName, style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.md),
          if (topics.isEmpty)
            Text('Không có dữ liệu topic.', style: AppTextStyles.bodySmall)
          else
            ...topics.map(
              (topic) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic['name'].toString(),
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${topic['count'] ?? 0}',
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

  String _avgCitations(Journal journal) {
    if (journal.worksCount <= 0) return '-';
    return (journal.citedByCount / journal.worksCount).toStringAsFixed(2);
  }

  List<TrendData> _publicationTrends(Journal journal) {
    final trends =
        journal.countsByYear
            .where((e) => e.year > 0)
            .map((e) => TrendData(year: e.year, count: e.worksCount))
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));
    return _takeRecent(trends);
  }

  List<TrendData> _citationTrends(Journal journal) {
    final trends =
        journal.countsByYear
            .where((e) => e.year > 0)
            .map((e) => TrendData(year: e.year, count: e.citedByCount))
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));
    return _takeRecent(trends);
  }

  List<TrendData> _takeRecent(List<TrendData> trends) {
    if (trends.length <= 15) return trends;
    return trends.sublist(trends.length - 15);
  }
}
