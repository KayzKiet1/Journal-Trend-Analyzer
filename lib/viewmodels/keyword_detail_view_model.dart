import 'package:flutter/foundation.dart';

import '../firebase/firebase_analytics_service.dart';
import '../models/publication_model.dart';
import '../models/trend_data_model.dart';
import '../services/openalex_service.dart';
import 'keywords_view_model.dart';

class KeywordDetailViewModel extends ChangeNotifier {
  KeywordDetailViewModel({
    OpenAlexService? apiService,
    FirebaseAnalyticsService? analyticsService,
  }) : _apiService = apiService ?? OpenAlexService(),
       _analyticsService = analyticsService ?? FirebaseAnalyticsService();

  final OpenAlexService _apiService;
  final FirebaseAnalyticsService _analyticsService;

  bool _isLoading = true;
  String _error = '';
  List<TrendData> _trends = [];
  List<Map<String, dynamic>> _journals = [];
  List<Map<String, dynamic>> _authors = [];
  List<Publication> _publications = [];
  int _totalPublications = 0;

  bool get isLoading => _isLoading;
  String get error => _error;
  List<TrendData> get trends => _trends;
  List<Map<String, dynamic>> get journals => _journals;
  List<Map<String, dynamic>> get authors => _authors;
  List<Publication> get publications => _publications;
  int get totalPublications => _totalPublications;

  Future<void> loadKeywordDetail({
    required String keywordId,
    required String keywordName,
    required List<String> topicIds,
    required String workQuery,
  }) async {
    await _analyticsService.logViewKeyword(keyword: keywordName);
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      const fromYear = KeywordsViewModel.analysisStartYear;
      final trends = await _apiService.getWorkSearchKeywordPublicationTrend(
        query: workQuery,
        topicIds: topicIds,
        keywordId: keywordId,
        fromYear: fromYear,
      );
      final journals = await _apiService.getWorkSearchKeywordTopJournals(
        query: workQuery,
        topicIds: topicIds,
        keywordId: keywordId,
        fromYear: fromYear,
        perPage: 5,
      );
      final authors = await _apiService.getWorkSearchKeywordTopAuthors(
        query: workQuery,
        topicIds: topicIds,
        keywordId: keywordId,
        fromYear: fromYear,
        perPage: 5,
      );
      final worksData = await _apiService.getWorksBySearchKeyword(
        query: workQuery,
        topicIds: topicIds,
        keywordId: keywordId,
        fromYear: fromYear,
        perPage: 5,
      );

      _trends = trends;
      _journals = journals;
      _authors = authors;
      _publications = worksData['results'] as List<Publication>;
      _totalPublications = worksData['total_count'] as int? ?? 0;
    } catch (error) {
      _error =
          'Could not load keyword analysis from OpenAlex for the selected journal article search: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
