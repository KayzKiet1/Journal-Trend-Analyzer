import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/controllers/publication_controller.dart';
import 'package:journal_trend_analyzer/models/author_model.dart';
import 'package:journal_trend_analyzer/models/journal_model.dart';
import 'package:journal_trend_analyzer/models/publication_model.dart';
import 'package:journal_trend_analyzer/models/research_topic_model.dart';
import 'package:journal_trend_analyzer/models/trend_data_model.dart';
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

    test('search times out instead of leaving loading active', () async {
      final controller = PublicationController.withTimeout(
        apiService: _HangingOpenAlexService(),
        searchTimeout: const Duration(milliseconds: 10),
      );

      await controller.search('slow network', 'Sources');

      expect(controller.isLoading, isFalse);
      expect(controller.sources, isEmpty);
      expect(controller.errorMessage, contains('OpenAlex phản hồi quá lâu'));
    });

    test('cancelActiveSearch stops a hanging search immediately', () async {
      final controller = PublicationController.withTimeout(
        apiService: _HangingOpenAlexService(),
        searchTimeout: const Duration(seconds: 5),
      );

      final searchFuture = controller.search('ai', 'Sources');
      await Future<void>.delayed(Duration.zero);

      expect(controller.isLoading, isTrue);

      controller.cancelActiveSearch(message: 'Search cancelled');

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, 'Search cancelled');

      await searchFuture;
      expect(controller.isLoading, isFalse);
      expect(controller.sources, isEmpty);
    });

    test(
      'search watchdog stops loading when request remains pending',
      () async {
        final controller = PublicationController.withTimeout(
          apiService: _NeverCompletingOpenAlexService(),
          searchTimeout: const Duration(seconds: 5),
          searchWatchdogTimeout: const Duration(milliseconds: 10),
        );

        unawaited(controller.search('ai', 'Sources'));
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(controller.isLoading, isFalse);
        expect(controller.sources, isEmpty);
        expect(controller.errorMessage, contains('Không nhận được phản hồi'));
      },
    );

    test('loadTopicDashboard builds overview from selected topics', () async {
      final controller = PublicationController(
        apiService: _FakeOpenAlexService(),
      );

      controller.selectTopic(
        const ResearchTopic(
          id: 'https://openalex.org/T1',
          name: 'Artificial Intelligence',
        ),
      );
      await controller.loadTopicDashboard();

      expect(controller.topicDashboardTotalWorks, 1);
      expect(controller.topicDashboardTrends.single.year, 2025);
      expect(controller.topicDashboardTopAuthors, {'Ada': 1});
      expect(controller.topicDashboardTopJournals, {'Journal': 1});
      expect(controller.topicDashboardTopPublication?.title, 'Topic work');
      expect(controller.topicDashboardAverageCitations, 5);
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
    String? topicId,
    List<String>? topicIds,
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

  @override
  Future<List<ResearchTopic>> searchTopics(String query, {int perPage = 5}) {
    return Future.value([
      const ResearchTopic(id: 'https://openalex.org/T1', name: 'Science'),
    ]);
  }

  @override
  Future<Map<String, dynamic>> getWorksByTopics(
    List<String> topicIds, {
    int page = 1,
    int perPage = 20,
  }) async {
    return {
      'results': [_publication('Topic work')],
      'total_count': 1,
    };
  }

  @override
  Future<List<TrendData>> getTopicPublicationTrend(List<String> topicIds) {
    return Future.value([TrendData(year: 2025, count: 1)]);
  }

  @override
  Future<Map<String, int>> getTopicTopAuthors(List<String> topicIds) {
    return Future.value({'Ada': 1});
  }

  @override
  Future<Map<String, int>> getTopicTopJournals(List<String> topicIds) {
    return Future.value({'Journal': 1});
  }
}

class _HangingOpenAlexService extends OpenAlexService {
  @override
  Future<Map<String, dynamic>> searchSources(
    String query, {
    int page = 1,
    int perPage = 10,
    String? topicId,
    List<String>? topicIds,
  }) {
    return Future<Map<String, dynamic>>.delayed(
      const Duration(seconds: 1),
      () => {'results': <Journal>[], 'total_count': 0},
    );
  }
}

class _NeverCompletingOpenAlexService extends OpenAlexService {
  @override
  Future<Map<String, dynamic>> searchSources(
    String query, {
    int page = 1,
    int perPage = 10,
    String? topicId,
    List<String>? topicIds,
  }) {
    return Completer<Map<String, dynamic>>().future;
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
