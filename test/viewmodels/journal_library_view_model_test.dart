import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/firebase/saved_items_sync_service.dart';
import 'package:journal_trend_analyzer/models/journal_model.dart';
import 'package:journal_trend_analyzer/viewmodels/journal_library_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(<Journal>[]);
    registerFallbackValue(_journal('fallback', 'Fallback'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('JournalLibraryViewModel', () {
    test('toggles favorite journals', () async {
      final controller = JournalLibraryViewModel();
      await Future<void>.delayed(Duration.zero);
      final journal = _journal('S1', 'Favorite Journal');

      await controller.toggleFavorite(journal);
      expect(controller.isFavorite('S1'), isTrue);
      expect(controller.favorites.single.name, 'Favorite Journal');

      await controller.toggleFavorite(journal);
      expect(controller.isFavorite('S1'), isFalse);
      expect(controller.favorites, isEmpty);
    });

    test(
      'stores recent journals with newest first and removes duplicates',
      () async {
        final controller = JournalLibraryViewModel();
        await Future<void>.delayed(Duration.zero);

        await controller.addRecentViewed(_journal('S1', 'One'));
        await controller.addRecentViewed(_journal('S2', 'Two'));
        await controller.addRecentViewed(_journal('S1', 'One again'));

        expect(controller.recentViewed.map((journal) => journal.id), [
          'S1',
          'S2',
        ]);
        expect(controller.recentViewed.first.name, 'One again');
      },
    );

    test('limits recent journals to ten and ignores empty ids', () async {
      final controller = JournalLibraryViewModel();
      await Future<void>.delayed(Duration.zero);

      await controller.addRecentViewed(_journal('', 'Invalid'));
      for (var i = 0; i < 12; i++) {
        await controller.addRecentViewed(_journal('S$i', 'Journal $i'));
      }

      expect(controller.recentViewed, hasLength(10));
      expect(controller.recentViewed.first.id, 'S11');
      expect(controller.recentViewed.last.id, 'S2');
    });

    test('clears recent journals', () async {
      final controller = JournalLibraryViewModel();
      await Future<void>.delayed(Duration.zero);

      await controller.addRecentViewed(_journal('S1', 'One'));
      await controller.clearRecentViewed();

      expect(controller.recentViewed, isEmpty);
    });

    test(
      'loads stored favorites and recent journals while skipping invalid rows',
      () async {
        SharedPreferences.setMockInitialValues({
          'favorite_journals': [
            jsonEncode(_journal('S1', 'Stored Favorite').toStoredJson()),
            'not-json',
            jsonEncode(_journal('', 'Missing id').toStoredJson()),
          ],
          'recent_viewed_journals': [
            jsonEncode(_journal('S2', 'Stored Recent').toStoredJson()),
          ],
        });

        final controller = JournalLibraryViewModel();
        await Future<void>.delayed(Duration.zero);

        expect(controller.favorites.map((journal) => journal.id), ['S1']);
        expect(controller.recentViewed.map((journal) => journal.id), ['S2']);
      },
    );

    test(
      'syncForSignedInUser uploads local favorites and merges cloud',
      () async {
        SharedPreferences.setMockInitialValues({
          'favorite_journals': [
            jsonEncode(_journal('S1', 'Local Favorite').toStoredJson()),
          ],
        });
        final syncService = _MockSavedItemsSyncService();
        when(() => syncService.hasSignedInUser).thenReturn(true);
        when(
          () => syncService.fetchSavedJournals(),
        ).thenAnswer((_) async => [_journal('S2', 'Cloud Favorite')]);
        when(() => syncService.saveJournals(any())).thenAnswer((_) async {});

        final controller = JournalLibraryViewModel(syncService: syncService);
        await Future<void>.delayed(Duration.zero);
        clearInteractions(syncService);

        await controller.syncForSignedInUser('U1');
        await controller.syncForSignedInUser('U1');

        expect(controller.favorites.map((journal) => journal.id), ['S1', 'S2']);
        verify(() => syncService.saveJournals(any())).called(1);
        verify(() => syncService.fetchSavedJournals()).called(1);
        verifyNever(() => syncService.removeJournal(any()));
      },
    );

    test('toggleFavorite keeps local state when cloud sync fails', () async {
      final syncService = _MockSavedItemsSyncService();
      when(() => syncService.fetchSavedJournals()).thenAnswer((_) async => []);
      when(() => syncService.hasSignedInUser).thenReturn(true);
      when(
        () => syncService.saveJournal(any()),
      ).thenThrow(Exception('rules denied'));

      final controller = JournalLibraryViewModel(syncService: syncService);
      await Future<void>.delayed(Duration.zero);

      await controller.toggleFavorite(_journal('S1', 'Unsynced Journal'));

      expect(controller.isFavorite('S1'), isTrue);
      expect(controller.syncMessage, contains('not synced to Firestore'));
    });
  });
}

Journal _journal(String id, String name) {
  return Journal(id: id, name: name, worksCount: 10, citedByCount: 20);
}

class _MockSavedItemsSyncService extends Mock
    implements SavedItemsSyncService {}
