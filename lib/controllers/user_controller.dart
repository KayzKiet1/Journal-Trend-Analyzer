import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bộ điều khiển quản lý thông tin người dùng (Profile) và lịch sử tìm kiếm
class UserController extends ChangeNotifier {
  String _email = '';
  String _apiKey = '';
  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';
  static const String _emailKey = 'user_email';
  static const String _apiKeyKey = 'openalex_api_key';
  
  String get email => _email;
  String get apiKey => _apiKey;
  List<String> get recentSearches => _recentSearches;
  
  UserController() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString(_emailKey) ?? '';
    _apiKey = prefs.getString(_apiKeyKey) ?? '';
    _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    notifyListeners();
  }
  
  /// Cập nhật email người dùng
  Future<void> updateEmail(String newEmail) async {
    _email = newEmail;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, newEmail);
    notifyListeners();
  }

  /// Cập nhật API Key người dùng
  Future<void> updateApiKey(String newKey) async {
    _apiKey = newKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, newKey);
    notifyListeners();
  }
  
  /// Thêm một tìm kiếm mới vào lịch sử
  Future<void> addSearch(String query) async {
    if (query.isEmpty) return;
    
    // Xóa nếu đã tồn tại để đưa lên đầu
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    
    // Giới hạn 5 mục tìm kiếm gần đây
    if (_recentSearches.length > 5) {
      _recentSearches.removeLast();
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
    notifyListeners();
  }

  /// Xóa lịch sử tìm kiếm
  Future<void> clearHistory() async {
    _recentSearches = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    notifyListeners();
  }
  
  /// Kiểm tra xem email đã được thiết lập chưa
  bool get hasEmail => _email.isNotEmpty && _email.contains('@');
}
