import 'package:flutter/foundation.dart';

import '../models/keyword_dashboard_model.dart';
import '../models/trend_data_model.dart';
import '../services/openalex_service.dart';
import '../utils/keyword_formatters.dart';

class KeywordsViewModel extends ChangeNotifier {
  KeywordsViewModel({OpenAlexService? apiService})
    : _apiService = apiService ?? OpenAlexService();

  OpenAlexService _apiService;
  String? _apiEmail;
  static const int analysisStartYear = 1995;

  List<Map<String, dynamic>> _topKeywords = [];
  List<KeywordGrowthData> _keywordGrowth = [];
  Map<String, List<TrendData>> _keywordTrends = {};
  bool _isLoading = false;
  String _errorMessage = '';
  String _loadedTopicKey = '';
  int _requestId = 0;

  List<Map<String, dynamic>> get topKeywords => _topKeywords;
  List<KeywordGrowthData> get keywordGrowth => _keywordGrowth;
  Map<String, List<TrendData>> get keywordTrends => _keywordTrends;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get loadedTopicKey => _loadedTopicKey;

  void syncApiService(String? email) {
    final normalizedEmail = email?.trim();
    if (_apiEmail == normalizedEmail) return;
    _apiEmail = normalizedEmail;
    _apiService = OpenAlexService(
      userEmail: normalizedEmail?.isEmpty == true ? null : normalizedEmail,
    );
  }

  Future<void> loadKeywordDashboard({
    required String query,
    required List<String> topicIds,
    required String topicKey,
  }) async {
    final requestId = ++_requestId;
    const fromYear = analysisStartYear;

    _isLoading = true;
    _errorMessage = '';
    _loadedTopicKey = topicKey;
    _keywordGrowth = [];
    _keywordTrends = {};
    notifyListeners();

    try {
      final topKeywords = await _apiService.getWorkSearchTopKeywords(
        query: query,
        topicIds: topicIds,
        fromYear: fromYear,
      );
      final trendingKeywords = await _apiService.getWorkSearchTrendingKeywords(
        query: query,
        topicIds: topicIds,
        fromYear: fromYear,
      );
      final keywordCandidates = _keywordGrowthCandidates(
        topKeywords: topKeywords,
        recentKeywords: trendingKeywords,
      );
      final keywordTrends = await _apiService.getWorkSearchKeywordTrends(
        query: query,
        topicIds: topicIds,
        keywordIds: keywordCandidates.map((keyword) => keyword.id).toList(),
        fromYear: fromYear,
        perKeyword: keywordCandidates.length,
      );
      final keywordGrowth = _buildKeywordGrowthData(
        keywordCandidates,
        keywordTrends,
      );

      if (requestId != _requestId) return;
      _topKeywords = topKeywords;
      _keywordGrowth = keywordGrowth;
      _keywordTrends = keywordTrends;
    } catch (error) {
      if (requestId != _requestId) return;
      _errorMessage = _formatKeywordDashboardError(error);
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  String _formatKeywordDashboardError(Object error) {
    final message = error.toString();
    final lowerMessage = message.toLowerCase();
    if (message.contains('429') ||
        lowerMessage.contains('too many requests') ||
        lowerMessage.contains('rate limit')) {
      return 'OpenAlex is rate limiting requests. The Keywords tab limits the number of analyzed keywords; please wait a moment and try again.';
    }

    return 'Could not load keywords from OpenAlex for the selected journal article search: $error';
  }

  List<KeywordCandidate> _keywordGrowthCandidates({
    required List<Map<String, dynamic>> topKeywords,
    required List<Map<String, dynamic>> recentKeywords,
  }) {
    const candidateLimit = 10;
    final candidates = <KeywordCandidate>[];
    final seenIds = <String>{};

    void addKeyword(Map<String, dynamic> keyword) {
      if (candidates.length >= candidateLimit) return;
      final rawId = keyword['id']?.toString() ?? '';
      final id = keywordId(rawId);
      if (id.isEmpty || !seenIds.add(id)) return;

      candidates.add(
        KeywordCandidate(
          id: id,
          name: keyword['name']?.toString() ?? id,
          totalCount: (keyword['count'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    for (final keyword in recentKeywords) {
      addKeyword(keyword);
    }
    for (final keyword in topKeywords) {
      addKeyword(keyword);
    }

    return candidates;
  }

  List<KeywordGrowthData> _buildKeywordGrowthData(
    List<KeywordCandidate> candidates,
    Map<String, List<TrendData>> keywordTrends,
  ) {
    final growthRows = <KeywordGrowthData>[];
    final latestCompleteYear = DateTime.now().year - 1;
    final recentWindowStartYear = latestCompleteYear - 4;

    for (final candidate in candidates) {
      final trends =
          [...?keywordTrends[candidate.id]]
              .where((trend) => trend.year >= analysisStartYear)
              .where((trend) => trend.year <= latestCompleteYear)
              .toList()
            ..sort((a, b) => a.year.compareTo(b.year));
      final nonZeroTrends = trends.where((trend) => trend.count > 0).toList();
      if (nonZeroTrends.isEmpty) continue;

      final recentTrends = nonZeroTrends
          .where((trend) => trend.year >= recentWindowStartYear)
          .toList();
      final comparisonTrends = recentTrends.length >= 2
          ? recentTrends
          : nonZeroTrends.length >= 2
          ? nonZeroTrends.sublist(nonZeroTrends.length - 2)
          : nonZeroTrends;
      if (comparisonTrends.length < 2) continue;

      final start = comparisonTrends.first;
      final end = comparisonTrends.last;
      if (start.count <= 0) continue;

      growthRows.add(
        KeywordGrowthData(
          id: candidate.id,
          name: candidate.name,
          totalCount: candidate.totalCount,
          startYear: start.year,
          startCount: start.count,
          endYear: end.year,
          endCount: end.count,
          growthRate: ((end.count - start.count) / start.count) * 100,
        ),
      );
    }

    growthRows.sort((a, b) {
      final byDirection = _momentumRank(b).compareTo(_momentumRank(a));
      if (byDirection != 0) return byDirection;
      final byGrowth = b.growthRate.compareTo(a.growthRate);
      if (byGrowth != 0) return byGrowth;
      return b.endCount.compareTo(a.endCount);
    });
    return growthRows;
  }

  int _momentumRank(KeywordGrowthData keyword) {
    if (keyword.endCount > keyword.startCount) return 2;
    if (keyword.endCount == keyword.startCount) return 1;
    return 0;
  }
}
