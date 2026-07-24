import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/models/author_model.dart';
import 'package:journal_trend_analyzer/models/publication_model.dart';
import 'package:journal_trend_analyzer/viewmodels/publication_bookmark_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PublicationBookmarkViewModel', () {
    test('loads stored bookmarks and skips invalid rows', () async {
      SharedPreferences.setMockInitialValues({
        'bookmarked_publications': [
          jsonEncode(_publication('W1', 'Stored paper').toStoredJson()),
          'not-json',
          jsonEncode(_publication('', 'Missing id').toStoredJson()),
        ],
      });

      final controller = PublicationBookmarkViewModel();
      await Future<void>.delayed(Duration.zero);

      expect(controller.bookmarks, hasLength(1));
      expect(controller.bookmarks.single.id, 'W1');
      expect(controller.bookmarks.single.title, 'Stored paper');
      expect(controller.isBookmarked('W1'), isTrue);
      expect(controller.isBookmarked('W2'), isFalse);
    });

    test(
      'toggleBookmark adds newest first and removes existing bookmarks',
      () async {
        final controller = PublicationBookmarkViewModel();
        await Future<void>.delayed(Duration.zero);

        await controller.toggleBookmark(_publication('W1', 'First paper'));
        await controller.toggleBookmark(_publication('W2', 'Second paper'));

        expect(controller.bookmarks.map((publication) => publication.id), [
          'W2',
          'W1',
        ]);
        expect(controller.isBookmarked('W1'), isTrue);

        await controller.toggleBookmark(_publication('W1', 'First paper'));

        expect(controller.bookmarks.map((publication) => publication.id), [
          'W2',
        ]);
        expect(controller.isBookmarked('W1'), isFalse);
      },
    );

    test('toggleBookmark ignores publications without ids', () async {
      final controller = PublicationBookmarkViewModel();
      await Future<void>.delayed(Duration.zero);

      await controller.toggleBookmark(_publication('', 'Invalid paper'));

      expect(controller.bookmarks, isEmpty);
    });

    test('clearBookmarks removes stored and in-memory bookmarks', () async {
      final controller = PublicationBookmarkViewModel();
      await Future<void>.delayed(Duration.zero);

      await controller.toggleBookmark(_publication('W1', 'First paper'));
      await controller.clearBookmarks();

      expect(controller.bookmarks, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('bookmarked_publications'), isNull);
    });
  });
}

Publication _publication(String id, String title) {
  return Publication(
    id: id,
    title: title,
    publicationYear: 2026,
    publicationDate: '2026-01-01',
    citedByCount: 12,
    journalId: 'S1',
    journalName: 'Journal of Bookmarks',
    authors: [Author(id: 'A1', name: 'Ada Lovelace')],
    doi: '10.1000/bookmark',
    abstractText: 'Bookmark persistence test.',
    topics: const ['Testing'],
    keywords: const ['coverage'],
  );
}
