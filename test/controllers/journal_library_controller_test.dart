import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/controllers/journal_library_controller.dart';
import 'package:journal_trend_analyzer/models/journal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('JournalLibraryController', () {
    test('toggles favorite journals', () async {
      final controller = JournalLibraryController();
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
        final controller = JournalLibraryController();
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
      final controller = JournalLibraryController();
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
      final controller = JournalLibraryController();
      await Future<void>.delayed(Duration.zero);

      await controller.addRecentViewed(_journal('S1', 'One'));
      await controller.clearRecentViewed();

      expect(controller.recentViewed, isEmpty);
    });
  });
}

Journal _journal(String id, String name) {
  return Journal(id: id, name: name, worksCount: 10, citedByCount: 20);
}
