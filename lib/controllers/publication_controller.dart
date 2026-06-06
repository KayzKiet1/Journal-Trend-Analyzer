import 'package:flutter/material.dart';
import '../models/publication_model.dart';
import '../services/openalex_service.dart';

/// Bộ điều khiển quản lý trạng thái của danh sách bài báo và tìm kiếm
class PublicationController extends ChangeNotifier {
  final OpenAlexService _apiService = OpenAlexService();
  
  List<Publication> _publications = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _currentTopic = '';

  List<Publication> get publications => _publications;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get currentTopic => _currentTopic;

  /// Thực hiện tìm kiếm bài báo theo chủ đề
  Future<void> searchByTopic(String topic) async {
    if (topic.isEmpty) return;
    
    _currentTopic = topic;
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _publications = await _apiService.searchWorks(topic);
      if (_publications.isEmpty) {
        _errorMessage = 'Không tìm thấy bài báo nào cho chủ đề này.';
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi: ${e.toString()}';
      _publications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa dữ liệu tìm kiếm hiện tại
  void clearSearch() {
    _publications = [];
    _currentTopic = '';
    _errorMessage = '';
    notifyListeners();
  }
}
