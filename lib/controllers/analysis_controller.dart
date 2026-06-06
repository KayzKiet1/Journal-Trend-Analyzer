import 'package:flutter/material.dart';
import '../models/trend_data_model.dart';
import '../services/openalex_service.dart';

/// Bộ điều khiển quản lý trạng thái của phân tích xu hướng và biểu đồ
class AnalysisController extends ChangeNotifier {
  final OpenAlexService _apiService = OpenAlexService();
  
  List<TrendData> _trends = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<TrendData> get trends => _trends;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Lấy dữ liệu xu hướng theo năm cho một chủ đề cụ thể
  Future<void> fetchTrendAnalysis(String topic) async {
    if (topic.isEmpty) return;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _trends = await _apiService.getYearlyTrend(topic);
      if (_trends.isEmpty) {
        _errorMessage = 'Không có dữ liệu xu hướng cho chủ đề này.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi phân tích xu hướng: ${e.toString()}';
      _trends = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
