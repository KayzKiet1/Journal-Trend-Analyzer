import 'package:flutter/material.dart';
import '../models/publication_model.dart';
import '../models/journal_model.dart';
import '../models/trend_data_model.dart';
import '../services/openalex_service.dart';

/// Bộ điều khiển quản lý trạng thái của danh sách bài báo và tìm kiếm đa thực thể
class PublicationController extends ChangeNotifier {
  OpenAlexService _apiService;

  PublicationController({OpenAlexService? apiService})
    : _apiService = apiService ?? OpenAlexService();

  /// Cập nhật email và API Key cho API service
  void updateApiService(String? email, {String? apiKey}) {
    _apiService = OpenAlexService(userEmail: email, apiKey: apiKey);
    notifyListeners();
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

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  void setSelectedIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  // Analysis persistence
  Journal? _lastAnalyzedJournal;
  Journal? get lastAnalyzedJournal => _lastAnalyzedJournal;
  List<TrendData>? _lastTrends;
  List<TrendData>? get lastTrends => _lastTrends;

  void setLastAnalysis(Journal? journal, List<TrendData>? trends) {
    _lastAnalyzedJournal = journal;
    _lastTrends = trends;
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
  String _errorMessage = '';
  String _currentTopic = '';

  int _currentPage = 1;
  int _totalResults = 0;
  final int _perPage = 10;

  List<Publication> get publications => _publications;
  List<Journal> get sources => _sources;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get errorMessage => _errorMessage;
  String get currentTopic => _currentTopic;
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
  }) async {
    // If query and category are same as last time and we have results, skip if not loading more
    if (!loadMore &&
        _lastFetchedQuery == query &&
        _lastFetchedCategory == category &&
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
      _currentCategory = category;
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 1;
      _totalResults = 0;
      _sources = [];
    }

    notifyListeners();

    try {
      switch (category) {
        case 'Sources':
          final data = await _apiService.searchSources(
            query,
            page: _currentPage,
            perPage: _perPage,
          );
          final List<Journal> results = data['results'];
          _totalResults = data['total_count'];

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
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi khi tìm kiếm: ${e.toString()}';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
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

  /// Xóa dữ liệu tìm kiếm
  void clearSearch() {
    _clearResults();
    _lastSearchText = '';
    _lastFetchedQuery = null;
    _lastFetchedCategory = null;
    _currentTopic = '';
    _errorMessage = '';
    notifyListeners();
  }
}
