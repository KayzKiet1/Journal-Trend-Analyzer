import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/firebase/saved_items_sync_service.dart';
import 'package:journal_trend_analyzer/models/author_model.dart';
import 'package:journal_trend_analyzer/models/publication_model.dart';
import 'package:journal_trend_analyzer/viewmodels/publication_bookmark_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(<Publication>[]);
    registerFallbackValue(_publication('fallback', 'Fallback'));
  });

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

    test(
      'syncForSignedInUser uploads local bookmarks and merges cloud bookmarks',
      () async {
        SharedPreferences.setMockInitialValues({
          'bookmarked_publications': [
            jsonEncode(_publication('W1', 'Local paper').toStoredJson()),
          ],
        });
        final syncService = _MockSavedItemsSyncService();
        when(() => syncService.hasSignedInUser).thenReturn(true);
        when(
          () => syncService.fetchSavedPublications(),
        ).thenAnswer((_) async => [_publication('W2', 'Cloud paper')]);
        when(
          () => syncService.savePublications(any()),
        ).thenAnswer((_) async {});

        final controller = PublicationBookmarkViewModel(
          syncService: syncService,
        );
        await Future<void>.delayed(Duration.zero);
        clearInteractions(syncService);

        await controller.syncForSignedInUser('U1');
        await controller.syncForSignedInUser('U1');

        expect(controller.bookmarks.map((publication) => publication.id), [
          'W1',
          'W2',
        ]);
        verify(() => syncService.savePublications(any())).called(1);
        verify(() => syncService.fetchSavedPublications()).called(1);
        verifyNever(() => syncService.removePublication(any()));
      },
    );

    test('toggleBookmark keeps local state when cloud sync fails', () async {
      final syncService = _MockSavedItemsSyncService();
      when(
        () => syncService.fetchSavedPublications(),
      ).thenAnswer((_) async => []);
      when(() => syncService.hasSignedInUser).thenReturn(true);
      when(
        () => syncService.savePublication(any()),
      ).thenThrow(Exception('rules denied'));

      final controller = PublicationBookmarkViewModel(syncService: syncService);
      await Future<void>.delayed(Duration.zero);

      await controller.toggleBookmark(_publication('W1', 'Unsynced paper'));

      expect(controller.isBookmarked('W1'), isTrue);
      expect(controller.syncMessage, contains('not synced to Firestore'));
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

class _MockSavedItemsSyncService extends Mock
    implements SavedItemsSyncService {}
