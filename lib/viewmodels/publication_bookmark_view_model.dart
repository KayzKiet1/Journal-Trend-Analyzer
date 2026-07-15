import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/publication_model.dart';

class PublicationBookmarkViewModel extends ChangeNotifier {
  static const String _bookmarkedPublicationsKey = 'bookmarked_publications';

  List<Publication> _bookmarks = [];

  List<Publication> get bookmarks => List.unmodifiable(_bookmarks);

  PublicationBookmarkViewModel() {
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
    } else {
      _bookmarks.insert(0, publication);
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

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarks = _decodePublications(
      prefs.getStringList(_bookmarkedPublicationsKey) ?? [],
    );
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
}
