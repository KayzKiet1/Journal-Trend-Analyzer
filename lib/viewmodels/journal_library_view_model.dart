import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/saved_items_sync_service.dart';
import '../models/journal_model.dart';

class JournalLibraryViewModel extends ChangeNotifier {
  static const String _favoriteJournalsKey = 'favorite_journals';
  static const String _recentViewedJournalsKey = 'recent_viewed_journals';
  static const int _recentLimit = 10;

  List<Journal> _favorites = [];
  List<Journal> _recentViewed = [];
  String? _syncMessage;
  final SavedItemsSyncService? _syncService;

  List<Journal> get favorites => List.unmodifiable(_favorites);
  List<Journal> get recentViewed => List.unmodifiable(_recentViewed);
  String? get syncMessage => _syncMessage;

  JournalLibraryViewModel({SavedItemsSyncService? syncService})
    : _syncService = syncService {
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
    await _mergeCloudFavorites();
    notifyListeners();
  }

  bool isFavorite(String journalId) {
    return _favorites.any((journal) => journal.id == journalId);
  }

  Future<void> toggleFavorite(Journal journal) async {
    final index = _favorites.indexWhere((item) => item.id == journal.id);
    if (index >= 0) {
      _favorites.removeAt(index);
      await _syncSavedJournal(journal, saved: false);
    } else {
      _favorites.insert(0, journal);
      await _syncSavedJournal(journal, saved: true);
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

  Future<void> _mergeCloudFavorites() async {
    if (_syncService == null && !SavedItemsSyncService.canUseDefaultFirebase) {
      return;
    }

    try {
      final service = _syncService ?? SavedItemsSyncService();
      final cloudFavorites = await service.fetchSavedJournals();
      if (cloudFavorites.isEmpty) return;

      final merged = <String, Journal>{};
      for (final journal in cloudFavorites.reversed) {
        merged[journal.id] = journal;
      }
      for (final journal in _favorites.reversed) {
        merged[journal.id] = journal;
      }
      _favorites = merged.values.toList().reversed.toList();
      await _saveList(_favoriteJournalsKey, _favorites);
      _syncMessage = null;
    } catch (error) {
      _syncMessage = 'Unable to load saved journals from Firestore: $error';
      debugPrint(_syncMessage);
    }
  }

  Future<void> _syncSavedJournal(Journal journal, {required bool saved}) async {
    if (_syncService == null && !SavedItemsSyncService.canUseDefaultFirebase) {
      return;
    }

    try {
      final service = _syncService ?? SavedItemsSyncService();
      if (saved) {
        await service.saveJournal(journal);
      } else {
        await service.removeJournal(journal.id);
      }
      _syncMessage = null;
    } catch (_) {
      _syncMessage =
          'Saved journal was kept locally but was not synced to Firestore. Check sign-in and Firestore Rules.';
    }
  }
}
