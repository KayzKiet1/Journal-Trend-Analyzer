import 'package:flutter/material.dart';
import '../models/publication_model.dart';
import '../models/author_model.dart';
import '../models/journal_model.dart';
import '../models/institution_model.dart';
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
  List<Author> _authors = [];
  List<Journal> _sources = [];
  List<Institution> _institutions = [];

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
  int _totalCitationsGlobal = 0;
  final int _perPage = 10;

  List<Publication> get publications => _publications;
  List<Author> get authors => _authors;
  List<Journal> get sources => _sources;
  List<Institution> get institutions => _institutions;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get errorMessage => _errorMessage;
  String get currentTopic => _currentTopic;
  int get totalResults => _totalResults;
  int get totalCitationsGlobal => _totalCitationsGlobal;

  bool get hasMore {
    switch (_currentCategory) {
      case 'Works':
      case 'AuthorWorks':
        return _publications.length < _totalResults;
      case 'Authors':
        return _authors.length < _totalResults;
      case 'Sources':
        return _sources.length < _totalResults;
      default:
        return false;
    }
  }

  String _currentCategory = 'Sources';
  String get currentCategory => _currentCategory;

  /// Thực hiện tìm kiếm theo loại thực thể (Works, Authors, Sources, Institutions)
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
      if (_isLoadingMore || !hasMore) return;
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
      _clearResults();
    }

    notifyListeners();

    try {
      switch (category) {
        case 'Works':
          final data = await _apiService.searchWorks(
            query,
            page: _currentPage,
            perPage: _perPage,
          );
          final List<Publication> results = data['results'];
          _totalResults = data['total_count'];

          // Tính tổng trích dẫn từ các bài báo hiện có
          if (!loadMore) {
            _totalCitationsGlobal = results.fold(
              0,
              (sum, item) => sum + item.citedByCount,
            );
          } else {
            _totalCitationsGlobal += results.fold(
              0,
              (sum, item) => sum + item.citedByCount,
            );
          }

          if (loadMore) {
            _publications.addAll(results);
          } else {
            _publications = results;
          }
          break;
        case 'Authors':
          final data = await _apiService.searchAuthors(
            query,
            page: _currentPage,
            perPage: _perPage,
          );
          final List<Author> results = data['results'];
          _totalResults = data['total_count'];

          if (loadMore) {
            _authors.addAll(results);
          } else {
            _authors = results;
          }
          break;
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
        case 'Institutions':
          _institutions = await _apiService.searchInstitutions(query);
          break;
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
    if (loadMore) {
      if (_isLoadingMore || !hasMore) return;
      _isLoadingMore = true;
      _currentPage++;
    } else {
      _currentTopic = 'Works by $authorName';
      _currentCategory = 'AuthorWorks';
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 1;
      _totalResults = 0;
      _clearResults();
    }
    notifyListeners();

    try {
      final data = await _apiService.getWorksByAuthor(
        authorId,
        page: _currentPage,
        perPage: _perPage,
      );
      final List<Publication> results = data['results'];
      _totalResults = data['total_count'];

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
    _authors = [];
    _sources = [];
    _institutions = [];
  }

  bool _isResultsEmpty(String category) {
    switch (category) {
      case 'Works':
        return _publications.isEmpty;
      case 'Authors':
        return _authors.isEmpty;
      case 'Sources':
        return _sources.isEmpty;
      case 'Institutions':
        return _institutions.isEmpty;
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

  /// Thực hiện tìm kiếm bài báo theo chủ đề (Legacy)
  Future<void> searchByTopic(String topic) async {
    await search(topic, 'Works');
  }
}
