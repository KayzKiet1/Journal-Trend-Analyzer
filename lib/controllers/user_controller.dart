import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase/firebase_auth_service.dart';
import '../models/research_topic_model.dart';

class RecentSearch {
  final String label;
  final List<String> topicIds;
  final List<String> topicNames;

  const RecentSearch({
    required this.label,
    this.topicIds = const [],
    this.topicNames = const [],
  });

  factory RecentSearch.fromStored(String value) {
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return RecentSearch(
        label: decoded['label']?.toString() ?? '',
        topicIds:
            (decoded['topic_ids'] as List?)
                ?.map((id) => id.toString())
                .toList() ??
            [],
        topicNames:
            (decoded['topic_names'] as List?)
                ?.map((name) => name.toString())
                .toList() ??
            [],
      );
    } catch (_) {
      return RecentSearch(label: value);
    }
  }

  String toStored() {
    if (topicIds.isEmpty) return label;
    return jsonEncode({
      'label': label,
      'topic_ids': topicIds,
      'topic_names': topicNames,
    });
  }
}

/// Bộ điều khiển quản lý thông tin người dùng (Profile) và lịch sử tìm kiếm
class UserController extends ChangeNotifier {
  final FirebaseAuthService _authService;
  String _email = '';
  String _apiKey = '';
  List<RecentSearch> _recentSearches = [];
  AuthenticatedUser? _firebaseUser;
  bool _isAuthLoading = false;
  String? _authError;
  StreamSubscription<AuthenticatedUser?>? _authSubscription;
  static const String _recentSearchesKey = 'recent_searches';
  static const String _emailKey = 'user_email';
  static const String _apiKeyKey = 'openalex_api_key';

  String get email => _email;
  String get apiKey => _apiKey;
  List<RecentSearch> get recentSearches => _recentSearches;
  AuthenticatedUser? get firebaseUser => _firebaseUser;
  String? get authError => _authError;
  bool get isAuthLoading => _isAuthLoading;
  bool get isSignedIn => _firebaseUser != null;
  String get authEmail => _firebaseUser?.email ?? '';
  String get authDisplayName =>
      _firebaseUser?.displayName ?? 'Người dùng Google';
  String? get authPhotoUrl => _firebaseUser?.photoUrl;

  UserController({FirebaseAuthService? authService})
    : _authService = authService ?? FirebaseAuthService() {
    _loadData();
    _listenToAuthState();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString(_emailKey) ?? '';
    _apiKey = prefs.getString(_apiKeyKey) ?? '';
    _recentSearches = (prefs.getStringList(_recentSearchesKey) ?? [])
        .map(RecentSearch.fromStored)
        .where((item) => item.label.isNotEmpty)
        .toList();
    notifyListeners();
  }

  void _listenToAuthState() {
    _firebaseUser = _authService.currentUser;
    _authSubscription = _authService.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user?.email != null && _email.isEmpty) {
        await updateEmail(user!.email);
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> signInWithGoogle() async {
    _setAuthLoading(true);
    try {
      await _authService.signInWithGoogle();
      _authError = null;
    } on AuthServiceException catch (error) {
      _authError = error.message;
    } finally {
      _setAuthLoading(false);
    }
  }

  Future<void> signOut() async {
    _setAuthLoading(true);
    try {
      await _authService.signOut();
      _authError = null;
    } on AuthServiceException catch (error) {
      _authError = error.message;
    } finally {
      _setAuthLoading(false);
    }
  }

  void _setAuthLoading(bool value) {
    _isAuthLoading = value;
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

    await _addRecentSearch(RecentSearch(label: query.trim()));
  }

  Future<void> addTopicSearch(List<ResearchTopic> topics) async {
    if (topics.isEmpty) return;

    final label = topics.map((topic) => topic.name).join(', ');
    await _addRecentSearch(
      RecentSearch(
        label: label,
        topicIds: topics.map((topic) => topic.id).toList(),
        topicNames: topics.map((topic) => topic.name).toList(),
      ),
    );
  }

  Future<void> _addRecentSearch(RecentSearch search) async {
    if (search.label.trim().isEmpty) return;

    _recentSearches.removeWhere((item) => item.label == search.label);
    _recentSearches.insert(0, search);

    // Giới hạn 5 mục tìm kiếm gần đây
    if (_recentSearches.length > 5) {
      _recentSearches.removeLast();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentSearchesKey,
      _recentSearches.map((item) => item.toStored()).toList(),
    );
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
