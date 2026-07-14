import 'package:flutter/foundation.dart';

import '../firebase/firebase_analytics_service.dart';
import '../models/journal_model.dart';
import '../models/trend_data_model.dart';
import '../services/openalex_service.dart';

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
  String _errorMessage = '';
  Journal? _journal;
  List<TrendData> _publicationTrends = [];
  List<TrendData> _citationTrends = [];
  List<JournalYearlyData> _yearlyData = [];
  List<Map<String, dynamic>> _topTopics = [];
  List<Map<String, dynamic>> _topAuthors = [];

  bool get isLoading => _isLoading;
  bool get isLoadingYearlyData => _isLoadingYearlyData;
  String get errorMessage => _errorMessage;
  Journal? get journal => _journal;
  List<TrendData> get publicationTrends => _publicationTrends;
  List<TrendData> get citationTrends => _citationTrends;
  List<JournalYearlyData> get yearlyData => _yearlyData;
  List<Map<String, dynamic>> get topTopics => _topTopics;
  List<Map<String, dynamic>> get topAuthors => _topAuthors;

  Future<void> load({
    required String journalId,
    required String journalName,
    required List<String> topicIds,
    required int chartStartYear,
    Journal? journalForTesting,
  }) async {
    await _analyticsService.logViewJournal(journalName: journalName);

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
      ]);

      final journal = results[0] as Journal;
      _journal = journal;
      _publicationTrends = results[1] as List<TrendData>;
      _topTopics = results[2] as List<Map<String, dynamic>>;
      _topAuthors = results[3] as List<Map<String, dynamic>>;
      _yearlyData = await _buildCurrentYearlyData(
        journal: journal,
        publicationTrends: _publicationTrends,
        topicIds: topicIds,
        startYear: chartStartYear,
      );
      _citationTrends = _yearlyData
          .where((data) => data.citedByCount > 0)
          .map((data) => TrendData(year: data.year, count: data.citedByCount))
          .toList();
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
      _yearlyData = await _buildCurrentYearlyData(
        journal: journal,
        publicationTrends: _publicationTrends,
        topicIds: topicIds,
        startYear: startYear,
      );
      _citationTrends = _yearlyData
          .where((data) => data.citedByCount > 0)
          .map((data) => TrendData(year: data.year, count: data.citedByCount))
          .toList();
    } catch (error) {
      _errorMessage = 'Could not update chart range: $error';
    } finally {
      _isLoadingYearlyData = false;
      notifyListeners();
    }
  }

  Future<List<JournalYearlyData>> _buildCurrentYearlyData({
    required Journal journal,
    required List<TrendData> publicationTrends,
    required List<String> topicIds,
    required int startYear,
  }) async {
    final currentYear = DateTime.now().year;
    final visiblePublicationTrends =
        publicationTrends
            .where(
              (trend) =>
                  trend.year >= startYear &&
                  trend.year <= currentYear &&
                  trend.count > 0,
            )
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));

    if (visiblePublicationTrends.isEmpty) return const [];

    try {
      final citationSums = await _apiService.getJournalCitationSumsByYear(
        journal.id,
        visiblePublicationTrends.map((trend) => trend.year),
        topicIds: topicIds,
      );

      return visiblePublicationTrends
          .map(
            (trend) => JournalYearlyData(
              year: trend.year,
              worksCount: trend.count,
              citedByCount: citationSums[trend.year] ?? 0,
            ),
          )
          .toList();
    } catch (_) {
      final sourceYearData = {
        for (final item in journal.countsByYear) item.year: item,
      };
      return visiblePublicationTrends.map((trend) {
        final sourceData = sourceYearData[trend.year];
        return JournalYearlyData(
          year: trend.year,
          worksCount: trend.count,
          citedByCount: sourceData?.citedByCount ?? 0,
        );
      }).toList();
    }
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
    trends.sort((a, b) => a.year.compareTo(b.year));
    return trends;
  }
}
