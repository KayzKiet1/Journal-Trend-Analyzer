import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/saved_items_sync_service.dart';
import '../models/publication_model.dart';

class PublicationBookmarkViewModel extends ChangeNotifier {
  static const String _bookmarkedPublicationsKey = 'bookmarked_publications';

  List<Publication> _bookmarks = [];
  String? _syncMessage;
  String? _lastSyncedUserId;
  bool _isSyncingCloud = false;
  final SavedItemsSyncService? _syncService;

  List<Publication> get bookmarks => List.unmodifiable(_bookmarks);
  String? get syncMessage => _syncMessage;

  PublicationBookmarkViewModel({SavedItemsSyncService? syncService})
    : _syncService = syncService {
    _loadData();
  }

  bool isBookmarked(String publicationId) {
    return _bookmarks.any((publication) => publication.id == publicationId);
  }

  Future<void> toggleBookmark(Publication publication) async {
    if (publication.id.isEmpty) return;

    final index = _bookmarks.indexWhere((item) => item.id == publication.id);
    if (index >= 0) {
      _bookmarks.removeAt(index);
      await _syncBookmark(publication, saved: false);
    } else {
      _bookmarks.insert(0, publication);
      await _syncBookmark(publication, saved: true);
    }
    await _saveBookmarks();
    notifyListeners();
  }

  Future<void> clearBookmarks() async {
    _bookmarks = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookmarkedPublicationsKey);
    notifyListeners();
  }

  Future<void> syncForSignedInUser(String? userId) async {
    if (userId == null || userId.isEmpty || _lastSyncedUserId == userId) {
      return;
    }
    if (_isSyncingCloud) return;

    _lastSyncedUserId = userId;
    await _syncLocalBookmarksToCloud();
    await _mergeCloudBookmarks();
    notifyListeners();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarks = _decodePublications(
      prefs.getStringList(_bookmarkedPublicationsKey) ?? [],
    );
    await _mergeCloudBookmarks();
    await _syncLocalBookmarksToCloud();
    notifyListeners();
  }

  List<Publication> _decodePublications(List<String> encodedItems) {
    return encodedItems
        .map((item) {
          try {
            return Publication.fromStoredJson(jsonDecode(item));
          } catch (_) {
            return null;
          }
        })
        .whereType<Publication>()
        .where((publication) => publication.id.isNotEmpty)
        .toList();
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _bookmarkedPublicationsKey,
      _bookmarks
          .map((publication) => jsonEncode(publication.toStoredJson()))
          .toList(),
    );
  }

  Future<void> _mergeCloudBookmarks() async {
    if (_syncService == null && !SavedItemsSyncService.canUseDefaultFirebase) {
      return;
    }

    try {
      final service = _syncService ?? SavedItemsSyncService();
      final cloudBookmarks = await service.fetchSavedPublications();
      if (cloudBookmarks.isEmpty) return;

      final merged = <String, Publication>{};
      for (final publication in cloudBookmarks.reversed) {
        merged[publication.id] = publication;
      }
      for (final publication in _bookmarks.reversed) {
        merged[publication.id] = publication;
      }
      _bookmarks = merged.values.toList().reversed.toList();
      await _saveBookmarks();
      _syncMessage = null;
    } catch (error) {
      _syncMessage = 'Unable to load saved publications from Firestore: $error';
      debugPrint(_syncMessage);
    }
  }

  Future<void> _syncLocalBookmarksToCloud() async {
    if (_bookmarks.isEmpty ||
        (_syncService == null &&
            !SavedItemsSyncService.canUseDefaultFirebase)) {
      return;
    }

    final service = _syncService ?? SavedItemsSyncService();
    if (!service.hasSignedInUser) return;

    _isSyncingCloud = true;
    try {
      await service.savePublications(_bookmarks);
      _syncMessage = null;
    } catch (error) {
      _syncMessage =
          'Saved publications were kept locally but were not synced to Firestore. Check sign-in and Firestore Rules. $error';
      debugPrint(_syncMessage);
    } finally {
      _isSyncingCloud = false;
    }
  }

  Future<void> _syncBookmark(
    Publication publication, {
    required bool saved,
  }) async {
    if (_syncService == null && !SavedItemsSyncService.canUseDefaultFirebase) {
      return;
    }

    try {
      final service = _syncService ?? SavedItemsSyncService();
      if (saved) {
        await service.savePublication(publication);
      } else {
        await service.removePublication(publication.id);
      }
      _syncMessage = null;
    } catch (error) {
      _syncMessage =
          'Saved publication was kept locally but was not synced to Firestore. Check sign-in and Firestore Rules. $error';
    }
  }
}
