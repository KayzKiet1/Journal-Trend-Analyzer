import 'package:flutter/foundation.dart';

import '../models/journal_model.dart';
import '../models/trend_data_model.dart';
import '../services/openalex_service.dart';

class CompareJournalsViewModel extends ChangeNotifier {
  CompareJournalsViewModel({OpenAlexService? apiService})
    : _apiService = apiService ?? OpenAlexService();

  final OpenAlexService _apiService;
  final List<Journal> _details = [];
  final Map<String, List<Map<String, dynamic>>> _topicsByJournal = {};

  bool _isLoading = true;
  bool _excludeFutureYears = true;
  String _errorMessage = '';

  List<Journal> get details => List.unmodifiable(_details);
  Map<String, List<Map<String, dynamic>>> get topicsByJournal =>
      Map.unmodifiable(_topicsByJournal);
  bool get isLoading => _isLoading;
  bool get excludeFutureYears => _excludeFutureYears;
  String get errorMessage => _errorMessage;
  int get currentYear => DateTime.now().year;

  set excludeFutureYears(bool value) {
    if (_excludeFutureYears == value) return;
    _excludeFutureYears = value;
    notifyListeners();
  }

  Future<void> loadComparisonData(List<Journal> journals) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final details = <Journal>[];
      final topicsByJournal = <String, List<Map<String, dynamic>>>{};

      for (final journal in journals.take(2)) {
        final detail = await _apiService.getJournalDetails(journal.id);
        final topics = await _apiService.getJournalTopTopics(journal.id);
        details.add(detail);
        topicsByJournal[detail.id] = topics;
      }

      _details
        ..clear()
        ..addAll(details);
      _topicsByJournal
        ..clear()
        ..addAll(topicsByJournal);
    } catch (error) {
      _errorMessage = 'Could not load comparison data: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String avgCitations(Journal journal) {
    final worksCount = worksCountForCompare(journal);
    if (worksCount <= 0) return '-';
    return (citationsForCompare(journal) / worksCount).toStringAsFixed(2);
  }

  List<TrendData> publicationTrends(Journal journal) {
    final trends =
        journal.countsByYear
            .where(_isUsableYear)
            .map((e) => TrendData(year: e.year, count: e.worksCount))
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));
    return _takeRecent(trends);
  }

  List<TrendData> citationTrends(Journal journal) {
    final trends =
        journal.countsByYear
            .where(_isUsableYear)
            .map((e) => TrendData(year: e.year, count: e.citedByCount))
            .toList()
          ..sort((a, b) => a.year.compareTo(b.year));
    return _takeRecent(trends);
  }

  int worksCountForCompare(Journal journal) {
    if (!_excludeFutureYears || journal.countsByYear.isEmpty) {
      return journal.worksCount;
    }

    return journal.countsByYear
        .where(_isUsableYear)
        .fold(0, (sum, data) => sum + data.worksCount);
  }

  int citationsForCompare(Journal journal) {
    if (!_excludeFutureYears || journal.countsByYear.isEmpty) {
      return journal.citedByCount;
    }

    return journal.countsByYear
        .where(_isUsableYear)
        .fold(0, (sum, data) => sum + data.citedByCount);
  }

  bool _isUsableYear(JournalYearlyData data) {
    if (data.year <= 0) return false;
    return !_excludeFutureYears || data.year <= currentYear;
  }

  List<TrendData> _takeRecent(List<TrendData> trends) {
    if (trends.length <= 15) return trends;
    return trends.sublist(trends.length - 15);
  }
}
