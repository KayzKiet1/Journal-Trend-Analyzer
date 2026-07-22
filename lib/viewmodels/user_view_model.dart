import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase/firebase_auth_service.dart';
import '../models/recent_search_model.dart';
import '../models/research_topic_model.dart';

/// ViewModel quản lý thông tin người dùng (Profile) và lịch sử tìm kiếm
class UserViewModel extends ChangeNotifier {
  final FirebaseAuthService _authService;
  String _email = '';
  String _apiKey = '';
  List<RecentSearch> _recentSearches = [];
  List<RecentSearch> _recentJournalSearches = [];
  List<RecentSearch> _recentKeywordSearches = [];
  AuthenticatedUser? _firebaseUser;
  bool _isAuthLoading = false;
  String? _authError;
  StreamSubscription<AuthenticatedUser?>? _authSubscription;
  static const String _recentSearchesKey = 'recent_searches';
  static const String _recentJournalSearchesKey = 'recent_journal_searches';
  static const String _recentKeywordSearchesKey = 'recent_keyword_searches';
  static const String _emailKey = 'user_email';
  static const String _apiKeyKey = 'openalex_api_key';
  static const int _recentSearchLimit = 10;

  String get email => _email;
  String get apiKey => _apiKey;
  List<RecentSearch> get recentSearches => _recentSearches;
  List<RecentSearch> get recentJournalSearches => _recentJournalSearches;
  List<RecentSearch> get recentKeywordSearches => _recentKeywordSearches;
  AuthenticatedUser? get firebaseUser => _firebaseUser;
  String? get authError => _authError;
  bool get isAuthLoading => _isAuthLoading;
  bool get isSignedIn => _firebaseUser != null;
  String get authEmail => _firebaseUser?.email ?? '';
  String get authDisplayName => _firebaseUser?.displayName ?? 'Google user';
  String? get authPhotoUrl => _firebaseUser?.photoUrl;

  UserViewModel({FirebaseAuthService? authService})
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
    _recentJournalSearches =
        (prefs.getStringList(_recentJournalSearchesKey) ?? [])
            .map(RecentSearch.fromStored)
            .where((item) => item.label.isNotEmpty)
            .toList();
    _recentKeywordSearches =
        (prefs.getStringList(_recentKeywordSearchesKey) ?? [])
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

  Future<void> addWorkSearch(String query, List<ResearchTopic> topics) async {
    final label = query.trim();
    if (label.isEmpty) return;

    await _addRecentSearch(RecentSearch(label: label));
  }

  Future<void> addJournalSearch(String query) async {
    final label = query.trim();
    if (label.isEmpty) return;

    await _addScopedRecentSearch(
      RecentSearch(label: label),
      history: _recentJournalSearches,
      storageKey: _recentJournalSearchesKey,
    );
  }

  Future<void> addKeywordSearch(String query) async {
    final label = query.trim();
    if (label.isEmpty) return;

    await _addScopedRecentSearch(
      RecentSearch(label: label),
      history: _recentKeywordSearches,
      storageKey: _recentKeywordSearchesKey,
    );
  }

  Future<void> _addScopedRecentSearch(
    RecentSearch search, {
    required List<RecentSearch> history,
    required String storageKey,
  }) async {
    history.removeWhere((item) => item.label == search.label);
    history.insert(0, search);

    if (history.length > _recentSearchLimit) {
      history.removeLast();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      storageKey,
      history.map((item) => item.toStored()).toList(),
    );
    notifyListeners();
  }

  Future<void> _addRecentSearch(RecentSearch search) async {
    if (search.label.trim().isEmpty) return;

    _recentSearches.removeWhere((item) => item.label == search.label);
    _recentSearches.insert(0, search);

    // Giới hạn 10 mục tìm kiếm gần đây
    if (_recentSearches.length > _recentSearchLimit) {
      _recentSearches.removeLast();
    }

    await _saveRecentSearches();
    notifyListeners();
  }

  Future<void> removeRecentSearch(RecentSearch search) async {
    _recentSearches.removeWhere(
      (item) =>
          item.label == search.label &&
          _sameList(item.topicIds, search.topicIds) &&
          _sameList(item.topicNames, search.topicNames),
    );
    await _saveRecentSearches();
    notifyListeners();
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentSearchesKey,
      _recentSearches.map((item) => item.toStored()).toList(),
    );
  }

  bool _sameList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
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
