import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/journal_model.dart';

class JournalLibraryController extends ChangeNotifier {
  static const String _favoriteJournalsKey = 'favorite_journals';
  static const String _recentViewedJournalsKey = 'recent_viewed_journals';
  static const int _recentLimit = 10;

  List<Journal> _favorites = [];
  List<Journal> _recentViewed = [];

  List<Journal> get favorites => List.unmodifiable(_favorites);
  List<Journal> get recentViewed => List.unmodifiable(_recentViewed);

  JournalLibraryController() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = _decodeJournals(
      prefs.getStringList(_favoriteJournalsKey) ?? [],
    );
    _recentViewed = _decodeJournals(
      prefs.getStringList(_recentViewedJournalsKey) ?? [],
    );
    notifyListeners();
  }

  bool isFavorite(String journalId) {
    return _favorites.any((journal) => journal.id == journalId);
  }

  Future<void> toggleFavorite(Journal journal) async {
    final index = _favorites.indexWhere((item) => item.id == journal.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.insert(0, journal);
    }
    await _saveList(_favoriteJournalsKey, _favorites);
    notifyListeners();
  }

  Future<void> addRecentViewed(Journal journal) async {
    if (journal.id.isEmpty) return;
    _recentViewed.removeWhere((item) => item.id == journal.id);
    _recentViewed.insert(0, journal);
    if (_recentViewed.length > _recentLimit) {
      _recentViewed = _recentViewed.take(_recentLimit).toList();
    }
    await _saveList(_recentViewedJournalsKey, _recentViewed);
    notifyListeners();
  }

  Future<void> clearRecentViewed() async {
    _recentViewed = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentViewedJournalsKey);
    notifyListeners();
  }

  List<Journal> _decodeJournals(List<String> encodedItems) {
    return encodedItems
        .map((item) {
          try {
            return Journal.fromStoredJson(jsonDecode(item));
          } catch (_) {
            return null;
          }
        })
        .whereType<Journal>()
        .where((journal) => journal.id.isNotEmpty)
        .toList();
  }

  Future<void> _saveList(String key, List<Journal> journals) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedItems = journals
        .map((journal) => jsonEncode(journal.toStoredJson()))
        .toList();
    await prefs.setStringList(key, encodedItems);
  }
}
