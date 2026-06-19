import 'package:flutter/material.dart';
import '../models/publication_model.dart';
import '../models/author_model.dart';
import '../models/journal_model.dart';
import '../models/institution_model.dart';
import '../services/openalex_service.dart';

/// Bộ điều khiển quản lý trạng thái của danh sách bài báo và tìm kiếm đa thực thể
class PublicationController extends ChangeNotifier {
  OpenAlexService _apiService = OpenAlexService();
  
  /// Cập nhật email cho API service
  void updateApiService(String? email) {
    _apiService = OpenAlexService(userEmail: email);
    notifyListeners();
  }
  
  List<Publication> _publications = [];
  List<Author> _authors = [];
  List<Journal> _sources = [];
  List<Institution> _institutions = [];
  
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
      default:
        return false;
    }
  }

  String _currentCategory = 'Works';
  String get currentCategory => _currentCategory;

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
      // Chỉ xóa dữ liệu của chính danh mục đang tìm kiếm
      _clearSpecificResults(category);
    }
    
    notifyListeners();

    try {
      switch (category) {
        case 'Works':
          final data = await _apiService.searchWorks(query, page: _currentPage, perPage: _perPage);
          final List<Publication> results = data['results'];
          _totalResults = data['total_count'];
          
          if (!loadMore) {
            int currentBatchCitations = results.fold(0, (sum, item) => sum + item.citedByCount);
            _totalCitationsGlobal = currentBatchCitations * 5; 
          }
          
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
        _errorMessage = 'Không tìm thấy kết quả nào.';
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi: ${e.toString()}';
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
      // Khi xem bài báo của tác giả, CHỈ XÓA danh sách bài báo cũ, KHÔNG XÓA danh sách tác giả
      _publications = []; 
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
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString()}';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _clearSpecificResults(String category) {
    switch (category) {
      case 'Works': _publications = []; break;
      case 'Authors': _authors = []; break;
      case 'Sources': _sources = []; break;
      case 'Institutions': _institutions = []; break;
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

  void clearSearch() {
    _clearResults();
    _currentTopic = '';
    _errorMessage = '';
    notifyListeners();
  }
}
