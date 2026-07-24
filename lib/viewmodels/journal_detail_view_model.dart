import 'package:flutter/foundation.dart';

import '../firebase/firebase_analytics_service.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../models/trend_data_model.dart';
import '../services/openalex_service.dart';

enum JournalPublicationSort {
  newest,
  mostCited;

  String get label {
    switch (this) {
      case JournalPublicationSort.newest:
        return 'Newest';
      case JournalPublicationSort.mostCited:
        return 'Most cited';
    }
  }
}

class JournalDetailViewModel extends ChangeNotifier {
  JournalDetailViewModel({
    OpenAlexService? apiService,
    FirebaseAnalyticsService? analyticsService,
  }) : _apiService = apiService ?? OpenAlexService(),
       _analyticsService = analyticsService ?? FirebaseAnalyticsService();

  final OpenAlexService _apiService;
  final FirebaseAnalyticsService _analyticsService;

  bool _isLoading = true;
  bool _isLoadingYearlyData = false;
  bool _isLoadingPublications = false;
  String _errorMessage = '';
  String _publicationsErrorMessage = '';
  Journal? _journal;
  List<TrendData> _publicationTrends = [];
  List<TrendData> _citationTrends = [];
  List<JournalYearlyData> _yearlyData = [];
  List<Map<String, dynamic>> _topTopics = [];
  List<Map<String, dynamic>> _topAuthors = [];
  List<Publication> _publications = [];
  int _publicationsTotalCount = 0;
  JournalPublicationSort _publicationSort = JournalPublicationSort.newest;

  bool get isLoading => _isLoading;
  bool get isLoadingYearlyData => _isLoadingYearlyData;
  bool get isLoadingPublications => _isLoadingPublications;
  String get errorMessage => _errorMessage;
  String get publicationsErrorMessage => _publicationsErrorMessage;
  Journal? get journal => _journal;
  List<TrendData> get publicationTrends => _publicationTrends;
  List<TrendData> get citationTrends => _citationTrends;
  List<JournalYearlyData> get yearlyData => _yearlyData;
  List<Map<String, dynamic>> get topTopics => _topTopics;
  List<Map<String, dynamic>> get topAuthors => _topAuthors;
  List<Publication> get publications => _publications;
  int get publicationsTotalCount => _publicationsTotalCount;
  JournalPublicationSort get publicationSort => _publicationSort;

  Future<void> load({
    required String journalId,
    required String journalName,
    required List<String> topicIds,
    required int chartStartYear,
    Journal? journalForTesting,
  }) async {
    await _analyticsService.logViewJournal(
      journalId: journalId,
      journalName: journalName,
    );

    if (journalForTesting != null) {
      _journal = journalForTesting;
      _publicationTrends = journalForTesting.countsByYear
          .map((item) => TrendData(year: item.year, count: item.worksCount))
          .toList();
      _citationTrends = _buildCitationTrends(journalForTesting);
      _yearlyData = journalForTesting.countsByYear;
      _topTopics = [
        {'name': 'Artificial Intelligence', 'count': 42},
        {'name': 'Machine Learning', 'count': 28},
      ];
      _topAuthors = [
        {'name': 'Ada Lovelace', 'count': 8},
        {'name': 'Alan Turing', 'count': 6},
      ];
      _publications = const [];
      _publicationsTotalCount = 0;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getJournalDetails(journalId),
        _apiService.getJournalYearlyTrend(journalId, topicIds: topicIds),
        _apiService.getJournalTopTopics(journalId),
        _apiService.getJournalTopAuthors(journalId, topicIds: topicIds),
        _apiService.getWorksByJournal(
          journalId,
          topicIds: topicIds,
          sortField: _sortFieldFor(_publicationSort),
          descending: true,
        ),
      ]);

      final journal = results[0] as Journal;
      _journal = journal;
      _publicationTrends = _dedupeTrendData(results[1] as List<TrendData>);
      _topTopics = results[2] as List<Map<String, dynamic>>;
      _topAuthors = results[3] as List<Map<String, dynamic>>;
      final worksData = results[4] as Map<String, dynamic>;
      _publications = worksData['results'] as List<Publication>;
      _publicationsTotalCount = worksData['total_count'] as int? ?? 0;
      _yearlyData = _buildCurrentYearlyData(
        journal: journal,
        publicationTrends: _publicationTrends,
        startYear: chartStartYear,
      );
      _citationTrends = _dedupeTrendData(
        _yearlyData
            .where((data) => data.citedByCount > 0)
            .map((data) => TrendData(year: data.year, count: data.citedByCount))
            .toList(),
      );
    } catch (error) {
      _errorMessage = 'Could not load journal: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChartRange({
    required int startYear,
    required List<String> topicIds,
  }) async {
    final journal = _journal;
    if (journal == null || _publicationTrends.isEmpty) return;

    _isLoadingYearlyData = true;
    notifyListeners();

    try {
      _yearlyData = _buildCurrentYearlyData(
        journal: journal,
        publicationTrends: _publicationTrends,
        startYear: startYear,
      );
      _citationTrends = _dedupeTrendData(
        _yearlyData
            .where((data) => data.citedByCount > 0)
            .map((data) => TrendData(year: data.year, count: data.citedByCount))
            .toList(),
      );
    } catch (error) {
      _errorMessage = 'Could not update chart range: $error';
    } finally {
      _isLoadingYearlyData = false;
      notifyListeners();
    }
  }

  Future<void> loadPublications({
    required String journalId,
    required List<String> topicIds,
    required JournalPublicationSort sort,
  }) async {
    if (_isLoadingPublications && sort == _publicationSort) return;

    _publicationSort = sort;
    _isLoadingPublications = true;
    _publicationsErrorMessage = '';
    notifyListeners();

    try {
      final data = await _apiService.getWorksByJournal(
        journalId,
        topicIds: topicIds,
        sortField: _sortFieldFor(sort),
        descending: true,
      );
      _publications = data['results'] as List<Publication>;
      _publicationsTotalCount = data['total_count'] as int? ?? 0;
    } catch (error) {
      _publicationsErrorMessage = 'Could not load publications: $error';
    } finally {
      _isLoadingPublications = false;
      notifyListeners();
    }
  }

  String? _sortFieldFor(JournalPublicationSort sort) {
    switch (sort) {
      case JournalPublicationSort.newest:
        return null;
      case JournalPublicationSort.mostCited:
        return 'cited_by_count';
    }
  }

  List<JournalYearlyData> _buildCurrentYearlyData({
    required Journal journal,
    required List<TrendData> publicationTrends,
    required int startYear,
  }) {
    final currentYear = DateTime.now().year;
    final visiblePublicationTrends = _dedupeTrendData(
      publicationTrends
          .where(
            (trend) =>
                trend.year >= startYear &&
                trend.year <= currentYear &&
                trend.count > 0,
          )
          .toList(),
    );

    if (visiblePublicationTrends.isEmpty) return const [];

    final sourceYearData = _dedupeYearlyData(journal.countsByYear);
    return visiblePublicationTrends.map((trend) {
      final sourceData = sourceYearData[trend.year];
      return JournalYearlyData(
        year: trend.year,
        worksCount: trend.count,
        citedByCount: sourceData?.citedByCount ?? 0,
      );
    }).toList();
  }

  List<TrendData> _buildCitationTrends(Journal journal) {
    final currentYear = DateTime.now().year;
    final trends = journal.countsByYear
        .where(
          (data) =>
              data.year > 0 &&
              data.year <= currentYear &&
              data.citedByCount > 0,
        )
        .map((data) => TrendData(year: data.year, count: data.citedByCount))
        .toList();
    return _dedupeTrendData(trends);
  }

  List<TrendData> _dedupeTrendData(List<TrendData> trends) {
    final byYear = <int, int>{};
    for (final trend in trends) {
      if (trend.year <= 0) continue;
      byYear[trend.year] = (byYear[trend.year] ?? 0) + trend.count;
    }
    return byYear.entries
        .map((entry) => TrendData(year: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));
  }

  Map<int, JournalYearlyData> _dedupeYearlyData(
    List<JournalYearlyData> yearlyData,
  ) {
    final byYear = <int, JournalYearlyData>{};
    for (final item in yearlyData) {
      if (item.year <= 0) continue;
      final existing = byYear[item.year];
      byYear[item.year] = JournalYearlyData(
        year: item.year,
        worksCount: (existing?.worksCount ?? 0) + item.worksCount,
        citedByCount: (existing?.citedByCount ?? 0) + item.citedByCount,
      );
    }
    return byYear;
  }
}
