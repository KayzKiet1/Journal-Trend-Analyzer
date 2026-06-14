import 'package:flutter/material.dart';
import '../models/publication_model.dart';
import '../models/author_model.dart';
import '../models/journal_model.dart';
import '../models/institution_model.dart';
import '../services/openalex_service.dart';

/// Bộ điều khiển quản lý trạng thái của danh sách bài báo và tìm kiếm đa thực thể
class PublicationController extends ChangeNotifier {
  final OpenAlexService _apiService = OpenAlexService();
  
  List<Publication> _publications = [];
  List<Author> _authors = [];
  List<Journal> _sources = [];
  List<Institution> _institutions = [];
  
  List<String> _popularTopics = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isTopicsLoading = false;
  String _errorMessage = '';
  String _currentTopic = '';
  
  int _currentPage = 1;
  int _totalResults = 0;
  final int _perPage = 10;

  List<Publication> get publications => _publications;
  List<Author> get authors => _authors;
  List<Journal> get sources => _sources;
  List<Institution> get institutions => _institutions;
  
  List<String> get popularTopics => _popularTopics;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isTopicsLoading => _isTopicsLoading;
  String get errorMessage => _errorMessage;
  String get currentTopic => _currentTopic;
  
  bool get hasMore {
    switch (_currentCategory) {
      case 'Works':
      case 'AuthorWorks':
        return _publications.length < _totalResults;
      case 'Authors':
        return _authors.length < _totalResults;
      default:
        return false;
    }
  }

  String _currentCategory = 'Works';
  String get currentCategory => _currentCategory;

  /// Lấy danh sách chủ đề phổ biến
  Future<void> fetchPopularTopics() async {
    _isTopicsLoading = true;
    notifyListeners();
    try {
      _popularTopics = await _apiService.getPopularTopics();
    } catch (e) {
      _popularTopics = ['Artificial Intelligence', 'Data Science', 'Software Engineering'];
    } finally {
      _isTopicsLoading = false;
      notifyListeners();
    }
  }

  /// Thực hiện tìm kiếm theo loại thực thể (Works, Authors, Sources, Institutions)
  Future<void> search(String query, String category, {bool loadMore = false}) async {
    if (query.isEmpty) return;
    
    if (loadMore) {
      if (_isLoadingMore || !hasMore) return;
      _isLoadingMore = true;
      _currentPage++;
    } else {
      _currentTopic = query;
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
          final data = await _apiService.searchWorks(query, page: _currentPage, perPage: _perPage);
          final List<Publication> results = data['results'];
          _totalResults = data['total_count'];
          
          if (loadMore) {
            _publications.addAll(results);
          } else {
            _publications = results;
          }
          break;
        case 'Authors':
          final data = await _apiService.searchAuthors(query, page: _currentPage, perPage: _perPage);
          final List<Author> results = data['results'];
          _totalResults = data['total_count'];
          
          if (loadMore) {
            _authors.addAll(results);
          } else {
            _authors = results;
          }
          break;
        case 'Sources':
          _sources = await _apiService.searchSources(query);
          break;
        case 'Institutions':
          _institutions = await _apiService.searchInstitutions(query);
          break;
      }
      
      if (!loadMore && _isResultsEmpty(category)) {
        _errorMessage = 'Không tìm thấy kết quả nào cho "${query}" trong mục ${category}.';
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
  Future<void> searchByAuthor(String authorId, String authorName, {bool loadMore = false}) async {
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
      final data = await _apiService.getWorksByAuthor(authorId, page: _currentPage, perPage: _perPage);
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
      case 'Works': return _publications.isEmpty;
      case 'Authors': return _authors.isEmpty;
      case 'Sources': return _sources.isEmpty;
      case 'Institutions': return _institutions.isEmpty;
      default: return true;
    }
  }

  /// Xóa dữ liệu tìm kiếm
  void clearSearch() {
    _clearResults();
    _currentTopic = '';
    _errorMessage = '';
    notifyListeners();
  }

  /// Thực hiện tìm kiếm bài báo theo chủ đề (Legacy)
  Future<void> searchByTopic(String topic) async {
    await search(topic, 'Works');
  }
}
