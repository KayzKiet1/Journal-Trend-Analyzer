import 'package:flutter/material.dart';
import '../firebase/firebase_analytics_service.dart';
import '../models/publication_model.dart';
import '../models/trend_data_model.dart';
import '../services/openalex_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/horizontal_bar_chart.dart';
import '../widgets/publication_card.dart';
import '../widgets/year_trend_chart.dart';
import 'publication_detail_screen.dart';

class KeywordDetailScreen extends StatefulWidget {
  final String keywordId;
  final String keywordName;
  final int keywordCount;
  final List<String> topicIds;
  final String topicLabel;

  const KeywordDetailScreen({
    super.key,
    required this.keywordId,
    required this.keywordName,
    required this.keywordCount,
    required this.topicIds,
    required this.topicLabel,
  });

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> {
  final OpenAlexService _apiService = OpenAlexService();
  final FirebaseAnalyticsService _analyticsService = FirebaseAnalyticsService();
  bool _isLoading = true;
  String _error = '';
  String _warning = '';
  List<TrendData> _trends = [];
  List<Map<String, dynamic>> _journals = [];
  List<Map<String, dynamic>> _authors = [];
  List<Publication> _publications = [];
  int _totalPublications = 0;

  @override
  void initState() {
    super.initState();
    _analyticsService.logViewKeyword(keyword: widget.keywordName);
    _loadKeywordDetail();
  }

  Future<void> _loadKeywordDetail() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _warning = '';
    });

    try {
      final warnings = <String>[];
      Future<T> loadPart<T>(
        String label,
        Future<T> Function() loader,
        T fallback,
      ) async {
        try {
          return await loader();
        } catch (_) {
          warnings.add(label);
          return fallback;
        }
      }

      final trends = await loadPart<List<TrendData>>(
        'publication trend',
        () => _apiService.getKeywordPublicationTrend(
          widget.topicIds,
          widget.keywordId,
        ),
        <TrendData>[],
      );
      final journals = await loadPart<List<Map<String, dynamic>>>(
        'related journals',
        () => _apiService.getKeywordTopJournals(
          widget.topicIds,
          widget.keywordId,
          perPage: 5,
        ),
        <Map<String, dynamic>>[],
      );
      final authors = await loadPart<List<Map<String, dynamic>>>(
        'top authors',
        () => _apiService.getKeywordTopAuthors(
          widget.topicIds,
          widget.keywordId,
          perPage: 5,
        ),
        <Map<String, dynamic>>[],
      );
      final worksData = await loadPart<Map<String, dynamic>>(
        'related publications',
        () => _apiService.getWorksByKeyword(
          widget.topicIds,
          widget.keywordId,
          perPage: 5,
        ),
        {'results': <Publication>[], 'total_count': 0},
      );

      if (!mounted) return;
      setState(() {
        _trends = trends;
        _journals = journals;
        _authors = authors;
        _publications = worksData['results'] as List<Publication>;
        _totalPublications = worksData['total_count'] as int? ?? 0;
        _warning = warnings.isEmpty
            ? ''
            : 'Some OpenAlex sections were temporarily skipped: ${warnings.join(', ')}.';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Could not load keyword analysis from OpenAlex for the selected Home topics: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Keyword Analysis')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _buildNotice(_error),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          const SizedBox(height: AppSpacing.lg),
          _buildSummary(),
          if (_warning.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildNotice(_warning),
          ],
          const SizedBox(height: AppSpacing.lg),
          YearTrendChart(
            trends: _trends,
            forceLineChart: true,
            title: 'Publication trend over time',
          ),
          const SizedBox(height: AppSpacing.lg),
          HorizontalBarChart(data: _journals, title: 'Related journals'),
          const SizedBox(height: AppSpacing.lg),
          HorizontalBarChart(data: _authors, title: 'Top authors'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Authors are ranked by the number of matching publications.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildPublicationSection(context),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
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
            'HOME TOPIC KEYWORD DETAIL',
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.surface.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.keywordName,
            style: AppTextStyles.h1.copyWith(
              color: AppColors.surface,
              fontSize: 26,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.topicLabel,
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
              _buildHeroBadge('${widget.topicIds.length} Home topics'),
              _buildHeroBadge('${_compactCount(widget.keywordCount)} matches'),
            ],
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

  Widget _buildPublicationSection(BuildContext context) {
    return _buildSectionCard(
      title: 'Related Publications',
      icon: Icons.article_outlined,
      child: _publications.isEmpty
          ? _buildNotice(
              'No related publications found for this Home topic scope.',
            )
          : Column(
              children: _publications.map((publication) {
                return PublicationCard(
                  title: publication.title,
                  year: publication.publicationYear.toString(),
                  journal: publication.journalName,
                  authors: publication.authorsString,
                  citations: publication.citedByCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PublicationDetailScreen(publication: publication),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSummary() {
    return _buildSectionCard(
      title: 'Analysis Scope',
      icon: Icons.radar_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_compactCount(_totalPublications)} journal publications match this keyword within the selected research topics.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Source: selected topics from Home.',
            style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent),
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

  Widget _buildNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(message, style: AppTextStyles.bodySmall),
    );
  }

  String _compactCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}
