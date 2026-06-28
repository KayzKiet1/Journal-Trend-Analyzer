import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/controllers/publication_controller.dart';
import 'package:journal_trend_analyzer/models/author_model.dart';
import 'package:journal_trend_analyzer/models/journal_model.dart';
import 'package:journal_trend_analyzer/models/publication_model.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';

void main() {
  group('PublicationController', () {
    test('search loads journal sources and supports pagination', () async {
      final service = _FakeOpenAlexService();
      final controller = PublicationController(apiService: service);

      await controller.search('medicine', 'Sources');

      expect(controller.sources.map((journal) => journal.id), ['S1']);
      expect(controller.totalResults, 2);
      expect(controller.hasMoreFor('Sources'), isTrue);

      await controller.search('medicine', 'Sources', loadMore: true);

      expect(controller.sources.map((journal) => journal.id), ['S1', 'S2']);
      expect(controller.hasMoreFor('Sources'), isFalse);
    });

    test(
      'search skips duplicate source queries when results are cached in state',
      () async {
        final service = _FakeOpenAlexService();
        final controller = PublicationController(apiService: service);

        await controller.search('science', 'Sources');
        await controller.search('science', 'Sources');

        expect(service.sourceSearchCalls, 1);
      },
    );

    test(
      'searchByAuthor loads works without clearing journal sources',
      () async {
        final service = _FakeOpenAlexService();
        final controller = PublicationController(apiService: service);

        await controller.search('journal', 'Sources');
        await controller.searchByAuthor('https://openalex.org/A1', 'Ada');

        expect(controller.sources, isNotEmpty);
        expect(controller.publications.single.title, 'Author work 1');
        expect(controller.hasMoreFor('AuthorWorks'), isTrue);

        await controller.searchByAuthor(
          'https://openalex.org/A1',
          'Ada',
          loadMore: true,
        );

        expect(controller.publications.map((pub) => pub.title), [
          'Author work 1',
          'Author work 2',
        ]);
      },
    );

    test('clearSearch resets search state', () async {
      final controller = PublicationController(
        apiService: _FakeOpenAlexService(),
      );

      await controller.search('journal', 'Sources');
      controller.clearSearch();

      expect(controller.sources, isEmpty);
      expect(controller.lastSearchText, isEmpty);
      expect(controller.errorMessage, isEmpty);
    });
  });
}

class _FakeOpenAlexService extends OpenAlexService {
  int sourceSearchCalls = 0;

  @override
  Future<Map<String, dynamic>> searchSources(
    String query, {
    int page = 1,
    int perPage = 10,
  }) async {
    sourceSearchCalls++;
    return {
      'results': [_journal('S$page')],
      'total_count': 2,
    };
  }

  @override
  Future<Map<String, dynamic>> getWorksByAuthor(
    String authorId, {
    int page = 1,
    int perPage = 10,
  }) async {
    return {
      'results': [_publication('Author work $page')],
      'total_count': 2,
    };
  }
}

Journal _journal(String id) {
  return Journal(id: id, name: 'Journal $id', worksCount: 10);
}

Publication _publication(String title) {
  return Publication(
    id: title,
    title: title,
    publicationYear: 2025,
    publicationDate: '2025-01-01',
    citedByCount: 5,
    journalName: 'Journal',
    authors: [Author(id: 'A1', name: 'Ada')],
    doi: '',
    abstractText: '',
    topics: const [],
  );
}
