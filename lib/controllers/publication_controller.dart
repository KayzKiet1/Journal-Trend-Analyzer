import 'dart:async';

import 'package:flutter/material.dart';
import '../models/publication_model.dart';
import '../models/journal_model.dart';
import '../models/research_topic_model.dart';
import '../models/trend_data_model.dart';
import '../services/openalex_service.dart';

/// Bộ điều khiển quản lý trạng thái của danh sách bài báo và tìm kiếm đa thực thể
class PublicationController extends ChangeNotifier {
  OpenAlexService _apiService;
  String? _apiEmail;
  String? _apiKeyValue;
  final Duration searchTimeout;
  final Duration searchWatchdogTimeout;

  PublicationController({OpenAlexService? apiService})
    : _apiService = apiService ?? OpenAlexService(),
      searchTimeout = const Duration(seconds: 15),
      searchWatchdogTimeout = const Duration(seconds: 12);

  PublicationController.withTimeout({
    OpenAlexService? apiService,
    required this.searchTimeout,
    this.searchWatchdogTimeout = const Duration(seconds: 12),
  }) : _apiService = apiService ?? OpenAlexService();

  /// Cập nhật email và API Key cho API service
  void updateApiService(String? email, {String? apiKey}) {
    syncApiService(email, apiKey: apiKey);
    notifyListeners();
  }

  void syncApiService(String? email, {String? apiKey}) {
    final normalizedEmail = email?.trim();
    final normalizedApiKey = apiKey?.trim();
    if (_apiEmail == normalizedEmail && _apiKeyValue == normalizedApiKey) {
      return;
    }

    _apiEmail = normalizedEmail;
    _apiKeyValue = normalizedApiKey;
    _apiService = OpenAlexService(
      userEmail: normalizedEmail?.isEmpty == true ? null : normalizedEmail,
      apiKey: normalizedApiKey?.isEmpty == true ? null : normalizedApiKey,
    );
  }

  List<Publication> _publications = [];
  List<Journal> _sources = [];

  String? _lastAuthorId;
  int _authorWorksPage = 1;
  int _authorWorksTotal = 0;

  String _lastSearchText = '';
  String get lastSearchText => _lastSearchText;

  String _lastSearchCategory = 'Sources';
  String get lastSearchCategory => _lastSearchCategory;

  String? _lastFetchedQuery;
  String? _lastFetchedCategory;
  String? _lastFetchedTopicKey;
  String? _activeSearchQuery;
  String? _activeSearchCategory;
  String? _activeSearchTopicKey;
  int _searchRequestId = 0;
  int _topicSuggestionRequestId = 0;
  Timer? _searchWatchdogTimer;

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  void setSelectedIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void updateSearchText(String text) {
    _lastSearchText = text;
  }

  void updateSearchCategory(String category) {
    _lastSearchCategory = category;
    notifyListeners();
  }

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingTopicSuggestions = false;
  String _errorMessage = '';
  String _topicSuggestionError = '';
  String _currentTopic = '';
  List<String> _currentTopicIds = [];
  List<ResearchTopic> _selectedTopics = [];
  List<ResearchTopic> _topicSuggestions = [];
  List<Publication> _topicDashboardPublications = [];
  List<TrendData> _topicDashboardTrends = [];
  Map<String, int> _topicDashboardTopAuthors = {};
  Map<String, int> _topicDashboardTopJournals = {};
  bool _isLoadingTopicDashboard = false;
  String _topicDashboardError = '';
  String? _topicDashboardTopicKey;
  int _topicDashboardTotalWorks = 0;
  double _topicDashboardAverageCitations = 0;
  int? _topicDashboardPeakYear;

  int _currentPage = 1;
  int _totalResults = 0;
  final int _perPage = 10;

  List<Publication> get publications => _publications;
  List<Journal> get sources => _sources;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingTopicSuggestions => _isLoadingTopicSuggestions;
  String get errorMessage => _errorMessage;
  String get topicSuggestionError => _topicSuggestionError;
  String get currentTopic => _currentTopic;
  List<String> get currentTopicIds => List.unmodifiable(_currentTopicIds);
  ResearchTopic? get selectedTopic =>
      _selectedTopics.isEmpty ? null : _selectedTopics.first;
  List<ResearchTopic> get selectedTopics => List.unmodifiable(_selectedTopics);
  List<ResearchTopic> get topicSuggestions => _topicSuggestions;
  List<Publication> get topicDashboardPublications =>
      _topicDashboardPublications;
  List<TrendData> get topicDashboardTrends => _topicDashboardTrends;
  Map<String, int> get topicDashboardTopAuthors => _topicDashboardTopAuthors;
  Map<String, int> get topicDashboardTopJournals => _topicDashboardTopJournals;
  bool get isLoadingTopicDashboard => _isLoadingTopicDashboard;
  String get topicDashboardError => _topicDashboardError;
  int get topicDashboardTotalWorks => _topicDashboardTotalWorks;
  double get topicDashboardAverageCitations => _topicDashboardAverageCitations;
  int? get topicDashboardPeakYear => _topicDashboardPeakYear;
  Publication? get topicDashboardTopPublication =>
      _topicDashboardPublications.isEmpty
      ? null
      : _topicDashboardPublications.first;
  int get totalResults => _totalResults;

  bool hasMoreFor(String category) {
    switch (category) {
      case 'AuthorWorks':
        return _publications.length < _authorWorksTotal;
      case 'Sources':
        return _sources.length < _totalResults;
      default:
        return false;
    }
  }

  bool get hasMore => hasMoreFor(_currentCategory);

  String _currentCategory = 'Sources';
  String get currentCategory => _currentCategory;

  /// Thực hiện tìm kiếm journal sources.
  Future<void> search(
    String query,
    String category, {
    bool loadMore = false,
    String? topicId,
    List<String>? topicIds,
  }) async {
    final effectiveTopicIds = _effectiveTopicIds(
      topicId: topicId,
      topicIds: topicIds,
    );
    final effectiveTopicKey = _topicKey(effectiveTopicIds);
    if (!loadMore &&
        _isLoading &&
        _activeSearchQuery == query &&
        _activeSearchCategory == category &&
        _activeSearchTopicKey == effectiveTopicKey) {
      return;
    }

    // If query and category are same as last time and we have results, skip if not loading more
    if (!loadMore &&
        _lastFetchedQuery == query &&
        _lastFetchedCategory == category &&
        _lastFetchedTopicKey == effectiveTopicKey &&
        !_isResultsEmpty(category) &&
        _errorMessage.isEmpty) {
      return;
    }

    // query can be empty for Sources to show default list
    if (query.isEmpty && category != 'Sources') return;

    if (loadMore) {
      if (_isLoadingMore || !hasMoreFor(category)) return;
      _isLoadingMore = true;
      _currentPage++;
    } else {
      _lastSearchText = query;
      _currentTopic = query.isEmpty ? 'Trending Journals' : query;
      _currentTopicIds = effectiveTopicIds;
      _currentCategory = category;
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 1;
      _totalResults = 0;
      _sources = [];
      _activeSearchQuery = query;
      _activeSearchCategory = category;
      _activeSearchTopicKey = effectiveTopicKey;
    }

    final requestId = ++_searchRequestId;
    if (!loadMore) {
      _startSearchWatchdog(requestId, query);
    }

    notifyListeners();

    try {
      switch (category) {
        case 'Sources':
          final data = await _apiService
              .searchSources(
                query,
                page: _currentPage,
                perPage: _perPage,
                topicIds: effectiveTopicIds,
              )
              .timeout(
                searchTimeout,
                onTimeout: () => throw TimeoutException(
                  'OpenAlex phản hồi quá lâu. Vui lòng kiểm tra mạng hoặc thử lại sau.',
                ),
              );
          final List<Journal> results = data['results'];
          _totalResults = data['total_count'];

          if (requestId != _searchRequestId) return;

          if (loadMore) {
            _sources.addAll(results);
          } else {
            _sources = results;
          }
          break;
        default:
          throw Exception('Danh mục tìm kiếm không được hỗ trợ: $category');
      }

      if (!loadMore && _isResultsEmpty(category)) {
        _errorMessage =
            'Không tìm thấy kết quả nào cho "$query" trong mục $category.';
      }

      if (!loadMore) {
        _lastFetchedQuery = query;
        _lastFetchedCategory = category;
        _lastFetchedTopicKey = effectiveTopicKey;
      }
    } catch (e) {
      if (requestId != _searchRequestId) return;
      _errorMessage = _formatSearchError(e);
    } finally {
      if (requestId == _searchRequestId) {
        _searchWatchdogTimer?.cancel();
        _isLoading = false;
        _isLoadingMore = false;
        if (!loadMore) {
          _activeSearchQuery = null;
          _activeSearchCategory = null;
          _activeSearchTopicKey = null;
        }
        notifyListeners();
      }
    }
  }

  void cancelActiveSearch({String? message}) {
    _searchWatchdogTimer?.cancel();
    _searchRequestId++;
    _isLoading = false;
    _isLoadingMore = false;
    _activeSearchQuery = null;
    _activeSearchCategory = null;
    _activeSearchTopicKey = null;
    if (message != null && message.isNotEmpty) {
      _errorMessage = message;
    }
    notifyListeners();
  }

  Future<void> loadTopicSuggestions(String query) async {
    final trimmedQuery = query.trim();
    _selectedTopics = [];

    if (trimmedQuery.length < 2) {
      _topicSuggestionRequestId++;
      _topicSuggestions = [];
      _topicSuggestionError = '';
      _isLoadingTopicSuggestions = false;
      notifyListeners();
      return;
    }

    final requestId = ++_topicSuggestionRequestId;
    _isLoadingTopicSuggestions = true;
    _topicSuggestionError = '';
    notifyListeners();

    try {
      final topics = await _apiService
          .searchTopics(trimmedQuery, perPage: 10)
          .timeout(const Duration(seconds: 8));
      if (requestId != _topicSuggestionRequestId) return;
      _topicSuggestions = topics;
      if (topics.isEmpty) {
        _topicSuggestionError = 'Không tìm thấy topic phù hợp.';
      }
    } catch (e) {
      if (requestId != _topicSuggestionRequestId) return;
      _topicSuggestions = [];
      _topicSuggestionError = _formatSearchError(e);
    } finally {
      if (requestId == _topicSuggestionRequestId) {
        _isLoadingTopicSuggestions = false;
        notifyListeners();
      }
    }
  }

  void toggleTopic(ResearchTopic topic) {
    final exists = _selectedTopics.any((item) => item.id == topic.id);
    if (exists) {
      _selectedTopics.removeWhere((item) => item.id == topic.id);
    } else {
      _selectedTopics = [..._selectedTopics, topic];
    }
    _lastSearchText = _selectedTopics.isEmpty
        ? _lastSearchText
        : _selectedTopics.map((item) => item.name).join(', ');
    notifyListeners();
  }

  void selectTopic(ResearchTopic topic) {
    _selectedTopics = [topic];
    _lastSearchText = topic.name;
    notifyListeners();
  }

  void setSelectedTopics(List<ResearchTopic> topics) {
    _selectedTopics = [...topics];
    _lastSearchText = topics.map((topic) => topic.name).join(', ');
    notifyListeners();
  }

  void clearTopicSelection() {
    _topicSuggestionRequestId++;
    _selectedTopics = [];
    _topicSuggestions = [];
    _topicSuggestionError = '';
    _isLoadingTopicSuggestions = false;
    notifyListeners();
  }

  void clearSelectedTopics() {
    _selectedTopics = [];
    notifyListeners();
  }

  Future<void> loadTopicDashboard() async {
    if (_selectedTopics.isEmpty) return;

    final topicIds = _selectedTopics.map((topic) => topic.id).toList();
    final topicKey = _topicKey(topicIds);
    if (_isLoadingTopicDashboard) return;
    if (_topicDashboardTopicKey == topicKey &&
        _topicDashboardError.isEmpty &&
        (_topicDashboardTotalWorks > 0 ||
            _topicDashboardPublications.isNotEmpty ||
            _topicDashboardTrends.isNotEmpty)) {
      return;
    }

    final requestId = ++_searchRequestId;
    final topicLabel = _selectedTopics.map((topic) => topic.name).join(', ');

    _lastSearchText = topicLabel;
    _currentTopic = topicLabel;
    _currentTopicIds = topicIds;
    _isLoadingTopicDashboard = true;
    _topicDashboardError = '';
    _topicDashboardPublications = [];
    _topicDashboardTrends = [];
    _topicDashboardTopAuthors = {};
    _topicDashboardTopJournals = {};
    _topicDashboardTopicKey = topicKey;
    _topicDashboardTotalWorks = 0;
    _topicDashboardAverageCitations = 0;
    _topicDashboardPeakYear = null;
    notifyListeners();

    try {
      final worksData = await _apiService
          .getWorksByTopics(topicIds, perPage: 20)
          .timeout(
            searchTimeout,
            onTimeout: () => throw TimeoutException(
              'OpenAlex phản hồi quá lâu khi tải công bố theo topic. Vui lòng thử lại sau.',
            ),
          );

      if (requestId != _searchRequestId) return;

      final publications = worksData['results'] as List<Publication>;
      _topicDashboardPublications = publications;
      _topicDashboardTotalWorks = worksData['total_count'] as int? ?? 0;
      _topicDashboardAverageCitations = _averageCitations(publications);
      _topicDashboardTopAuthors = _rankAuthorsFromPublications(publications);
      _topicDashboardTopJournals = _rankJournalsFromPublications(publications);

      final trends = await _loadOptionalDashboardPart<List<TrendData>>(
        () => _apiService.getTopicPublicationTrend(topicIds),
        fallback: const [],
      );
      if (requestId != _searchRequestId) return;
      _topicDashboardTrends = trends;

      final journalData =
          await _loadOptionalDashboardPart<Map<String, dynamic>>(
        () => _apiService.searchSources(
          topicLabel,
          topicIds: topicIds,
          perPage: 10,
        ),
        fallback: {
          'results': _journalsFromPublications(publications),
          'total_count': _rankJournalsFromPublications(publications).length,
        },
      );
      if (requestId != _searchRequestId) return;
      _sources = journalData['results'] as List<Journal>;
      _totalResults = journalData['total_count'] as int? ?? _sources.length;
      _currentCategory = 'Sources';
      _topicDashboardPeakYear = _peakYear(trends);

      if (_topicDashboardTotalWorks == 0) {
        _topicDashboardError = 'Không tìm thấy công bố cho topic đã chọn.';
      }
    } catch (e) {
      if (requestId != _searchRequestId) return;
      _topicDashboardError = _formatSearchError(e);
    } finally {
      if (requestId == _searchRequestId) {
        _isLoadingTopicDashboard = false;
        notifyListeners();
      }
    }
  }

  /// Tìm kiếm bài báo theo tác giả
  Future<void> searchByAuthor(
    String authorId,
    String authorName, {
    bool loadMore = false,
  }) async {
    final isSameAuthor = _lastAuthorId == authorId;

    if (!loadMore &&
        isSameAuthor &&
        _currentCategory == 'AuthorWorks' &&
        _publications.isNotEmpty &&
        _errorMessage.isEmpty) {
      return;
    }

    if (loadMore) {
      if (_isLoadingMore || _publications.length >= _authorWorksTotal) return;
      _isLoadingMore = true;
      _authorWorksPage++;
    } else {
      _currentTopic = 'Works by $authorName';
      _currentCategory = 'AuthorWorks';
      _isLoading = true;
      _errorMessage = '';
      _authorWorksPage = 1;
      _authorWorksTotal = 0;
      _lastAuthorId = authorId;
      _publications = [];
    }
    notifyListeners();

    try {
      final data = await _apiService.getWorksByAuthor(
        authorId,
        page: _authorWorksPage,
        perPage: _perPage,
      );
      final List<Publication> results = data['results'];
      _authorWorksTotal = data['total_count'];

      if (loadMore) {
        _publications.addAll(results);
      } else {
        _publications = results;
      }

      if (!loadMore && _publications.isEmpty) {
        _errorMessage = 'Không tìm thấy bài báo nào của tác giả này.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi khi tải bài báo của tác giả: ${e.toString()}';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _clearResults() {
    _publications = [];
    _sources = [];
    _lastAuthorId = null;
    _authorWorksPage = 1;
    _authorWorksTotal = 0;
  }

  bool _isResultsEmpty(String category) {
    switch (category) {
      case 'Sources':
        return _sources.isEmpty;
      default:
        return true;
    }
  }

  List<String> _effectiveTopicIds({String? topicId, List<String>? topicIds}) {
    final ids = [
      ...?topicIds,
      ?topicId,
      if (topicIds == null && topicId == null) ..._currentTopicIds,
    ].map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList();
    return ids;
  }

  String? _topicKey(List<String> topicIds) {
    if (topicIds.isEmpty) return null;
    final sortedIds = [...topicIds]..sort();
    return sortedIds.join('|');
  }

  double _averageCitations(List<Publication> publications) {
    if (publications.isEmpty) return 0;
    final total = publications.fold<int>(
      0,
      (sum, publication) => sum + publication.citedByCount,
    );
    return total / publications.length;
  }

  int? _peakYear(List<TrendData> trends) {
    if (trends.isEmpty) return null;
    final sorted = [...trends]
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return b.year.compareTo(a.year);
      });
    return sorted.first.year;
  }

  Future<T> _loadOptionalDashboardPart<T>(
    Future<T> Function() loader, {
    required T fallback,
  }) async {
    try {
      return await loader().timeout(searchTimeout);
    } catch (_) {
      return fallback;
    }
  }

  Map<String, int> _rankAuthorsFromPublications(
    List<Publication> publications,
  ) {
    final counts = <String, int>{};
    for (final publication in publications) {
      for (final author in publication.authors) {
        final name = author.name.trim();
        if (name.isEmpty || name.toLowerCase() == 'unknown author') continue;
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    return _topEntries(counts, limit: 5);
  }

  Map<String, int> _rankJournalsFromPublications(
    List<Publication> publications,
  ) {
    final counts = <String, int>{};
    for (final publication in publications) {
      final journal = publication.journalName.trim();
      if (journal.isEmpty || journal.toLowerCase() == 'unknown journal') {
        continue;
      }
      counts[journal] = (counts[journal] ?? 0) + 1;
    }
    return _topEntries(counts, limit: 5);
  }

  Map<String, int> _topEntries(Map<String, int> values, {required int limit}) {
    final entries = values.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });
    return Map.fromEntries(entries.take(limit));
  }

  List<Journal> _journalsFromPublications(List<Publication> publications) {
    final journalsByName = <String, Journal>{};
    final counts = <String, int>{};
    for (final publication in publications) {
      final name = publication.journalName.trim();
      if (name.isEmpty || name.toLowerCase() == 'unknown journal') continue;
      counts[name] = (counts[name] ?? 0) + 1;
      journalsByName.putIfAbsent(
        name,
        () => Journal(
          id: publication.journalId,
          name: name,
          type: 'journal',
        ),
      );
    }

    return _topEntries(counts, limit: 10).entries.map((entry) {
      final journal = journalsByName[entry.key]!;
      return Journal(
        id: journal.id,
        name: journal.name,
        type: journal.type,
        worksCount: entry.value,
      );
    }).toList();
  }

  String _formatSearchError(Object error) {
    if (error is TimeoutException) {
      return error.message ??
          'OpenAlex phản hồi quá lâu. Vui lòng kiểm tra mạng hoặc thử lại sau.';
    }

    final message = error.toString();
    if (message.contains('429') ||
        message.toLowerCase().contains('too many requests') ||
        message.toLowerCase().contains('rate limit') ||
        message.toLowerCase().contains('giới hạn tốc độ')) {
      return 'OpenAlex đang giới hạn số lần truy cập. Vui lòng đợi một chút rồi thử lại.';
    }

    return 'Đã xảy ra lỗi khi tìm kiếm: ${error.toString()}';
  }

  void _startSearchWatchdog(int requestId, String query) {
    _searchWatchdogTimer?.cancel();
    _searchWatchdogTimer = Timer(searchWatchdogTimeout, () {
      if (requestId != _searchRequestId || !_isLoading || _sources.isNotEmpty) {
        return;
      }

      cancelActiveSearch(
        message:
            'Không nhận được phản hồi từ OpenAlex cho "$query". Hãy kiểm tra Internet hoặc quyền mạng của ứng dụng rồi thử lại.',
      );
    });
  }

  /// Xóa dữ liệu tìm kiếm
  void clearSearch() {
    _searchWatchdogTimer?.cancel();
    _clearResults();
    _lastSearchText = '';
    _lastFetchedQuery = null;
    _lastFetchedCategory = null;
    _lastFetchedTopicKey = null;
    _currentTopic = '';
    _currentTopicIds = [];
    _selectedTopics = [];
    _topicSuggestions = [];
    _topicSuggestionError = '';
    _isLoadingTopicSuggestions = false;
    _topicDashboardPublications = [];
    _topicDashboardTrends = [];
    _topicDashboardTopAuthors = {};
    _topicDashboardTopJournals = {};
    _isLoadingTopicDashboard = false;
    _topicDashboardError = '';
    _topicDashboardTopicKey = null;
    _topicDashboardTotalWorks = 0;
    _topicDashboardAverageCitations = 0;
    _topicDashboardPeakYear = null;
    _errorMessage = '';
    notifyListeners();
  }
}
