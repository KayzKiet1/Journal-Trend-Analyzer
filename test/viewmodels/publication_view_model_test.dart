import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/models/author_model.dart';
import 'package:journal_trend_analyzer/models/journal_model.dart';
import 'package:journal_trend_analyzer/models/publication_model.dart';
import 'package:journal_trend_analyzer/models/research_topic_model.dart';
import 'package:journal_trend_analyzer/models/trend_data_model.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';
import 'package:journal_trend_analyzer/viewmodels/publication_view_model.dart';

void main() {
  group('PublicationViewModel', () {
    test('search loads journal sources and supports pagination', () async {
      final service = _FakeOpenAlexService();
      final controller = PublicationViewModel(apiService: service);

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
        final controller = PublicationViewModel(apiService: service);

        await controller.search('science', 'Sources');
        await controller.search('science', 'Sources');

        expect(service.sourceSearchCalls, 1);
      },
    );

    test(
      'searchByAuthor loads works without clearing journal sources',
      () async {
        final service = _FakeOpenAlexService();
        final controller = PublicationViewModel(apiService: service);

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
      final controller = PublicationViewModel(
        apiService: _FakeOpenAlexService(),
      );

      await controller.search('journal', 'Sources');
      controller.clearSearch();

      expect(controller.sources, isEmpty);
      expect(controller.lastSearchText, isEmpty);
      expect(controller.errorMessage, isEmpty);
    });

    test('search times out instead of leaving loading active', () async {
      final controller = PublicationViewModel.withTimeout(
        apiService: _HangingOpenAlexService(),
        searchTimeout: const Duration(milliseconds: 10),
      );

      await controller.search('slow network', 'Sources');

      expect(controller.isLoading, isFalse);
      expect(controller.sources, isEmpty);
      expect(controller.errorMessage, contains('OpenAlex took too long'));
    });

    test('search shows friendly message when OpenAlex rate limits', () async {
      final controller = PublicationViewModel(
        apiService: _RateLimitedOpenAlexService(),
      );

      await controller.search('military', 'Sources');

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, contains('rate limiting requests'));
    });

    test('cancelActiveSearch stops a hanging search immediately', () async {
      final controller = PublicationViewModel.withTimeout(
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
        final controller = PublicationViewModel.withTimeout(
          apiService: _NeverCompletingOpenAlexService(),
          searchTimeout: const Duration(seconds: 5),
          searchWatchdogTimeout: const Duration(milliseconds: 10),
        );

        unawaited(controller.search('ai', 'Sources'));
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(controller.isLoading, isFalse);
        expect(controller.sources, isEmpty);
        expect(controller.errorMessage, contains('No response from OpenAlex'));
      },
    );

    test('loadTopicDashboard builds overview from selected topics', () async {
      final controller = PublicationViewModel(
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

    test('loadWorkSearchDashboard builds overview from works search', () async {
      final controller = PublicationViewModel(
        apiService: _FakeOpenAlexService(),
      );

      await controller.loadWorkSearchDashboard('artificial intelligence');

      expect(controller.currentWorkQuery, 'artificial intelligence');
      expect(controller.currentWorkTopicIds, isEmpty);
      expect(controller.topicDashboardTotalWorks, 1);
      expect(controller.topicDashboardTrends.single.year, 2025);
      expect(controller.topicDashboardTopAuthors, {'Ada': 1});
      expect(controller.topicDashboardTopJournals, {'Journal': 1});
      expect(controller.topicDashboardTopPublication?.title, 'Search work');
    });

    test(
      'autoSelectTopicsForQuery selects top suggestions for Home search',
      () async {
        final controller = PublicationViewModel(
          apiService: _ManyTopicsOpenAlexService(),
        );

        final didSelect = await controller.autoSelectTopicsForQuery(
          'artificial intelligence',
        );

        expect(didSelect, isTrue);
        expect(controller.selectedTopics.map((topic) => topic.id), [
          'https://openalex.org/T1',
          'https://openalex.org/T2',
          'https://openalex.org/T3',
        ]);
        expect(controller.lastSearchText, 'Topic 1, Topic 2, Topic 3');
      },
    );

    test('basic setters, sync service and topic selection update state', () {
      final controller = PublicationViewModel(
        apiService: _FakeOpenAlexService(),
      );

      controller.updateApiService(' student@example.com ', apiKey: ' key ');
      controller.syncApiService('student@example.com', apiKey: 'key');
      controller.setSelectedIndex(2);
      controller.updateSearchText('ai');
      controller.updateSearchCategory('Sources');
      controller.toggleTopic(
        const ResearchTopic(id: 'T1', name: 'Artificial Intelligence'),
      );
      controller.toggleTopic(
        const ResearchTopic(id: 'T2', name: 'Machine Learning'),
      );

      expect(controller.selectedTabIndex, 2);
      expect(
        controller.lastSearchText,
        'Artificial Intelligence, Machine Learning',
      );
      expect(controller.lastSearchCategory, 'Sources');
      expect(controller.selectedTopic?.id, 'T1');

      controller.toggleTopic(
        const ResearchTopic(id: 'T1', name: 'Artificial Intelligence'),
      );
      expect(controller.selectedTopics.map((topic) => topic.id), ['T2']);

      controller.clearSelectedTopics();
      expect(controller.selectedTopics, isEmpty);
    });

    test(
      'seedE2eFixtures fills dashboard, journals and suggestion state',
      () async {
        final controller = PublicationViewModel(
          apiService: _FakeOpenAlexService(),
        );

        controller.seedE2eFixtures(
          topic: 'AI',
          topicIds: ['T1'],
          publications: [_publication('Seed work')],
          trends: [
            TrendData(year: 2024, count: 2),
            TrendData(year: 2025, count: 5),
          ],
          topAuthors: {'Ada': 1},
          topJournals: {'Journal': 1},
          journals: [_journal('S1')],
          keywords: [
            {'id': 'K1', 'name': 'Deep learning', 'count': 3},
          ],
        );

        expect(controller.hasTestingFixtures, isTrue);
        expect(controller.currentWorkScopeLabel, 'AI - AI');
        expect(controller.topicDashboardPeakYear, 2025);
        expect(controller.topicDashboardAverageCitations, 5);
        expect(controller.journalSourcesTotal, 1);
        expect(controller.keywordFixtures.single['name'], 'Deep learning');

        await controller.loadTopicSuggestions('ai');
        expect(controller.topicSuggestions.single.name, 'AI');

        await controller.loadWorkSearchDashboard('ai research');
        expect(controller.currentWorkQuery, 'ai research');
        expect(controller.topicDashboardError, isEmpty);
      },
    );

    test(
      'topic suggestion handles short, empty and failing searches',
      () async {
        final controller = PublicationViewModel(
          apiService: _EmptyTopicsOpenAlexService(),
        );

        await controller.loadTopicSuggestions('a');
        expect(controller.topicSuggestions, isEmpty);
        expect(controller.topicSuggestionError, isEmpty);

        await controller.loadTopicSuggestions('missing');
        expect(controller.topicSuggestions, isEmpty);
        expect(controller.topicSuggestionError, 'No matching topics found.');

        final failing = PublicationViewModel(
          apiService: _FailingTopicsOpenAlexService(),
        );
        await failing.loadTopicSuggestions('network');
        expect(failing.topicSuggestionError, contains('Search failed'));
      },
    );

    test('dashboard skips duplicates and records empty/error states', () async {
      final service = _FakeOpenAlexService();
      final controller = PublicationViewModel(apiService: service);

      await controller.loadWorkSearchDashboard('ai');
      await controller.loadWorkSearchDashboard('ai');
      expect(service.workSearchCalls, 1);
      expect(controller.hasActiveWorkSearch, isTrue);
      expect(controller.currentWorkScopeLabel, 'ai');

      final empty = PublicationViewModel(
        apiService: _EmptyWorksOpenAlexService(),
      );
      await empty.loadWorkSearchDashboard('unknown');
      expect(empty.topicDashboardError, contains('No journal publications'));
      expect(empty.topicDashboardTopPublication, isNull);
      expect(empty.topicDashboardPeakYear, isNull);

      final failing = PublicationViewModel(
        apiService: _FailingWorksOpenAlexService(),
      );
      await failing.loadWorkSearchDashboard('broken');
      expect(failing.topicDashboardError, contains('Search failed'));
    });

    test(
      'loadTopicDashboard handles empty selection, cache and fallbacks',
      () async {
        final service = _JournalFallbackOpenAlexService();
        final controller = PublicationViewModel(apiService: service);

        await controller.loadTopicDashboard();
        expect(controller.topicDashboardTotalWorks, 0);

        controller.setSelectedTopics([
          const ResearchTopic(id: 'T2', name: 'Data Science'),
        ]);
        await controller.loadTopicDashboard();
        await controller.loadTopicDashboard();

        expect(service.topicWorkCalls, 1);
        expect(controller.currentTopicIds, ['T2']);
        expect(controller.sources.single.name, 'Journal');
        expect(controller.totalResults, 1);
      },
    );

    test(
      'search and author branches handle unsupported and empty states',
      () async {
        final controller = PublicationViewModel(
          apiService: _EmptyWorksOpenAlexService(),
        );

        await controller.search('', 'Works');
        expect(controller.isLoading, isFalse);

        await controller.search('anything', 'Unsupported');
        expect(
          controller.errorMessage,
          contains('Unsupported search category'),
        );

        await controller.searchByAuthor('A1', 'Nobody');
        expect(
          controller.errorMessage,
          'No publications found for this author.',
        );
        expect(controller.hasMore, isFalse);
      },
    );
  });
}

class _FakeOpenAlexService extends OpenAlexService {
  int sourceSearchCalls = 0;
  int workSearchCalls = 0;

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
  Future<Map<String, dynamic>> searchJournalSourcesByTopic(
    String topicQuery, {
    String? topicId,
    List<String>? topicIds,
    int page = 1,
    int perPage = 10,
  }) async {
    return {
      'results': [_journal('TopicJournal')],
      'total_count': 1,
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
  Future<Map<String, dynamic>> searchWorks({
    required String query,
    List<String> topicIds = const [],
    int page = 1,
    int perPage = 20,
  }) async {
    workSearchCalls++;
    return {
      'results': [_publication('Search work')],
      'total_count': 1,
    };
  }

  @override
  Future<List<TrendData>> getWorkSearchPublicationTrend({
    required String query,
    List<String> topicIds = const [],
  }) {
    return Future.value([TrendData(year: 2025, count: 1)]);
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

class _RateLimitedOpenAlexService extends OpenAlexService {
  @override
  Future<Map<String, dynamic>> searchSources(
    String query, {
    int page = 1,
    int perPage = 10,
    String? topicId,
    List<String>? topicIds,
  }) {
    throw Exception('OpenAlex API 429 Too Many Requests');
  }
}

class _ManyTopicsOpenAlexService extends _FakeOpenAlexService {
  @override
  Future<List<ResearchTopic>> searchTopics(String query, {int perPage = 5}) {
    return Future.value([
      const ResearchTopic(id: 'https://openalex.org/T1', name: 'Topic 1'),
      const ResearchTopic(id: 'https://openalex.org/T2', name: 'Topic 2'),
      const ResearchTopic(id: 'https://openalex.org/T3', name: 'Topic 3'),
      const ResearchTopic(id: 'https://openalex.org/T4', name: 'Topic 4'),
    ]);
  }
}

class _EmptyTopicsOpenAlexService extends _FakeOpenAlexService {
  @override
  Future<List<ResearchTopic>> searchTopics(String query, {int perPage = 5}) {
    return Future.value([]);
  }
}

class _FailingTopicsOpenAlexService extends _FakeOpenAlexService {
  @override
  Future<List<ResearchTopic>> searchTopics(String query, {int perPage = 5}) {
    throw StateError('network unavailable');
  }
}

class _EmptyWorksOpenAlexService extends _FakeOpenAlexService {
  @override
  Future<Map<String, dynamic>> searchWorks({
    required String query,
    List<String> topicIds = const [],
    int page = 1,
    int perPage = 20,
  }) async {
    return {'results': <Publication>[], 'total_count': 0};
  }

  @override
  Future<List<TrendData>> getWorkSearchPublicationTrend({
    required String query,
    List<String> topicIds = const [],
  }) {
    return Future.value([]);
  }

  @override
  Future<Map<String, dynamic>> getWorksByAuthor(
    String authorId, {
    int page = 1,
    int perPage = 10,
  }) async {
    return {'results': <Publication>[], 'total_count': 0};
  }
}

class _FailingWorksOpenAlexService extends _FakeOpenAlexService {
  @override
  Future<Map<String, dynamic>> searchWorks({
    required String query,
    List<String> topicIds = const [],
    int page = 1,
    int perPage = 20,
  }) {
    throw StateError('OpenAlex exploded');
  }
}

class _JournalFallbackOpenAlexService extends _FakeOpenAlexService {
  int topicWorkCalls = 0;

  @override
  Future<Map<String, dynamic>> getWorksByTopics(
    List<String> topicIds, {
    int page = 1,
    int perPage = 20,
  }) async {
    topicWorkCalls++;
    return {
      'results': [_publication('Topic fallback work')],
      'total_count': 1,
    };
  }

  @override
  Future<List<TrendData>> getTopicPublicationTrend(List<String> topicIds) {
    throw StateError('trend down');
  }

  @override
  Future<Map<String, dynamic>> searchJournalSourcesByTopic(
    String topicQuery, {
    String? topicId,
    List<String>? topicIds,
    int page = 1,
    int perPage = 10,
  }) {
    throw StateError('journal down');
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
