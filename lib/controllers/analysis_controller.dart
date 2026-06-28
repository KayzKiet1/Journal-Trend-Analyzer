import 'package:flutter/material.dart';
import '../models/trend_data_model.dart';
import '../services/openalex_service.dart';

/// Bộ điều khiển quản lý trạng thái của phân tích xu hướng và biểu đồ
class AnalysisController extends ChangeNotifier {
  OpenAlexService _apiService;
  
  AnalysisController({OpenAlexService? apiService}) : _apiService = apiService ?? OpenAlexService();
  
  /// Cập nhật email và API Key cho API service
  void updateApiService(String? email, {String? apiKey}) {
    _apiService = OpenAlexService(userEmail: email, apiKey: apiKey);
    notifyListeners();
  }

  List<TrendData> _trends = [];
  List<Map<String, dynamic>> _topKeywords = [];
  List<Map<String, dynamic>> _countryData = [];
  List<Map<String, dynamic>> _topAuthors = [];
  List<Map<String, dynamic>> _topJournals = [];
  List<Map<String, dynamic>> _institutions = [];
  List<Map<String, dynamic>> _quartiles = [];
  List<Map<String, dynamic>> _topInfluentialWorks = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<TrendData> get trends => _trends;
  List<Map<String, dynamic>> get topKeywords => _topKeywords;
  List<Map<String, dynamic>> get countryData => _countryData;
  List<Map<String, dynamic>> get topAuthors => _topAuthors;
  List<Map<String, dynamic>> get topJournals => _topJournals;
  List<Map<String, dynamic>> get institutions => _institutions;
  List<Map<String, dynamic>> get quartiles => _quartiles;
  List<Map<String, dynamic>> get topInfluentialWorks => _topInfluentialWorks;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Lấy toàn bộ dữ liệu phân tích cho một chủ đề cụ thể
  Future<void> fetchTrendAnalysis(String topic) async {
    if (topic.isEmpty) return;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Gọi song song các API để tối ưu tốc độ
      final results = await Future.wait([
        _apiService.getYearlyTrend(topic),
        _apiService.getTopKeywords(topic),
        _apiService.getCountryOutput(topic),
        _apiService.getTopAuthorsByTopic(topic),
        _apiService.getTopJournals(topic),
        _apiService.getInstitutionRanking(topic),
        _apiService.getQuartileDistribution(topic),
        _apiService.getTopInfluentialWorks(topic),
      ]);

      _trends = List<TrendData>.from(results[0]);
      _topKeywords = List<Map<String, dynamic>>.from(results[1]);
      _countryData = List<Map<String, dynamic>>.from(results[2]);
      _topAuthors = List<Map<String, dynamic>>.from(results[3]);
      _topJournals = List<Map<String, dynamic>>.from(results[4]);
      _institutions = List<Map<String, dynamic>>.from(results[5]);
      _quartiles = List<Map<String, dynamic>>.from(results[6]);
      _topInfluentialWorks = List<Map<String, dynamic>>.from(results[7]);

      if (_trends.isEmpty && _topKeywords.isEmpty) {
        _errorMessage = 'Không có dữ liệu phân tích cho chủ đề này.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi phân tích: ${e.toString()}';
      _trends = [];
      _topKeywords = [];
      _countryData = [];
      _topAuthors = [];
      _topJournals = [];
      _institutions = [];
      _quartiles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
