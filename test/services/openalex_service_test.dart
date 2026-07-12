import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';

void main() {
  setUp(OpenAlexService.resetForTesting);

  group('OpenAlexService', () {
    test('retries transient OpenAlex 504 responses', () async {
      var calls = 0;
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          calls++;
          if (calls == 1) {
            return http.Response(
              jsonEncode({'message': 'Gateway timeout'}),
              504,
              headers: {'content-type': 'application/json'},
            );
          }
          return _jsonResponse({
            'group_by': [
              {
                'key': 'https://openalex.org/keywords/computer-science',
                'key_display_name': 'Computer science',
                'count': 3,
              },
            ],
          });
        }),
      );

      final keywords = await service.getTopicTopKeywords(['T1']);

      expect(calls, 2);
      expect(keywords.single['name'], 'Computer science');
    });

    test('searchSources searches OpenAlex journal sources directly', () async {
      final requestedUrls = <Uri>[];
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          requestedUrls.add(request.url);
          return _jsonResponse({
            'meta': {'count': 1},
            'results': [
              {
                'id': 'https://openalex.org/S1',
                'display_name': 'Journal Analytics',
                'type': 'journal',
                'works_count': 100,
                'cited_by_count': 250,
              },
            ],
          });
        }),
      );

      final result = await service.searchSources('analytics');

      expect(result['total_count'], 1);
      expect(result['results'].single.name, 'Journal Analytics');
      expect(requestedUrls.single.path, endsWith('/sources'));
      expect(requestedUrls.single.queryParameters['filter'], 'type:journal');
      expect(requestedUrls.single.queryParameters['search'], 'analytics');
    });

    test('searchSources without input loads trending journals', () async {
      Uri? requestedUrl;
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          requestedUrl = request.url;
          return _jsonResponse({
            'meta': {'count': 1},
            'results': [
              {
                'id': 'https://openalex.org/S1',
                'display_name': 'Journal Analytics',
                'type': 'journal',
                'works_count': 100,
                'cited_by_count': 250,
              },
            ],
          });
        }),
      );

      final result = await service.searchSources('');

      expect(result['total_count'], 1);
      expect(result['results'].single.name, 'Journal Analytics');
      expect(requestedUrl!.queryParameters['filter'], 'type:journal');
      expect(requestedUrl!.queryParameters.containsKey('search'), isFalse);
    });

    test('searchTopics returns topic suggestions', () async {
      Uri? requestedUrl;
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          requestedUrl = request.url;
          return _jsonResponse({
            'results': [
              {
                'id': 'https://openalex.org/T1',
                'display_name': 'Machine learning',
                'hint': 'Algorithms that learn from data',
                'works_count': 42,
              },
            ],
          });
        }),
      );

      final topics = await service.searchTopics('machine');

      expect(topics.single.id, 'https://openalex.org/T1');
      expect(topics.single.name, 'Machine learning');
      expect(topics.single.worksCount, 42);
      expect(requestedUrl!.path, endsWith('/autocomplete/topics'));
      expect(requestedUrl!.queryParameters['q'], 'machine');
      expect(requestedUrl!.queryParameters.containsKey('per_page'), isFalse);
    });

    test('searchTopics sorts suggestions by works count descending', () async {
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          return _jsonResponse({
            'results': [
              {
                'id': 'https://openalex.org/T1',
                'display_name': 'Small topic',
                'works_count': 10,
              },
              {
                'id': 'https://openalex.org/T2',
                'display_name': 'Large topic',
                'works_count': 100,
              },
            ],
          });
        }),
      );

      final topics = await service.searchTopics('topic');

      expect(topics.map((topic) => topic.name), ['Large topic', 'Small topic']);
    });

    test('searchTopics limits autocomplete results client-side', () async {
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          return _jsonResponse({
            'results': [
              {
                'id': 'https://openalex.org/T1',
                'display_name': 'Topic 1',
                'works_count': 30,
              },
              {
                'id': 'https://openalex.org/T2',
                'display_name': 'Topic 2',
                'works_count': 20,
              },
            ],
          });
        }),
      );

      final topics = await service.searchTopics('topic', perPage: 1);

      expect(topics.map((topic) => topic.name), ['Topic 1']);
    });

    test(
      'searchTopics prefers suggestions whose names match the query',
      () async {
        final service = OpenAlexService(
          minRequestInterval: Duration.zero,
          client: MockClient((request) async {
            return _jsonResponse({
              'results': [
                {
                  'id': 'https://openalex.org/T1',
                  'display_name': 'History of Computing Technologies',
                  'works_count': 348600,
                  'hint': 'Includes artificial intelligence history.',
                },
                {
                  'id': 'https://openalex.org/T2',
                  'display_name': 'Artificial Intelligence in Healthcare',
                  'works_count': 78750,
                },
              ],
            });
          }),
        );

        final topics = await service.searchTopics('artificial');

        expect(topics.map((topic) => topic.name), [
          'Artificial Intelligence in Healthcare',
        ]);
      },
    );

    test(
      'searchJournalSourcesByTopic uses selected topic id without resolving again',
      () async {
        Uri? requestedUrl;
        final service = OpenAlexService(
          minRequestInterval: Duration.zero,
          client: MockClient((request) async {
            requestedUrl = request.url;
            return _jsonResponse({
              'group_by': [
                {
                  'key': 'https://openalex.org/S1',
                  'key_display_name': 'Selected Topic Journal',
                  'count': 12,
                },
              ],
            });
          }),
        );

        final result = await service.searchJournalSourcesByTopic(
          'Machine learning',
          topicId: 'https://openalex.org/T1',
        );

        expect(result['results'].single.name, 'Selected Topic Journal');
        expect(requestedUrl!.path, endsWith('/works'));
        expect(
          requestedUrl!.queryParameters['filter'],
          'primary_topic.id:T1,primary_location.source.type:journal',
        );
      },
    );

    test('getTopicTopKeywords groups works by keyword id', () async {
      Uri? requestedUrl;
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          requestedUrl = request.url;
          return _jsonResponse({
            'group_by': [
              {
                'key': 'https://openalex.org/keywords/computer-science',
                'key_display_name': 'Computer science',
                'count': 10,
              },
            ],
          });
        }),
      );

      final keywords = await service.getTopicTopKeywords([
        'https://openalex.org/T1',
      ]);

      expect(keywords.single['name'], 'Computer science');
      expect(requestedUrl!.queryParameters['group_by'], 'keywords.id');
      expect(
        requestedUrl!.queryParameters['filter'],
        'primary_topic.id:T1,primary_location.source.type:journal',
      );
    });

    test('getTopicKeywordTrends filters by selected keyword id', () async {
      Uri? requestedUrl;
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          requestedUrl = request.url;
          return _jsonResponse({
            'group_by': [
              {'key': '2024', 'count': 3},
              {'key': '2023', 'count': 2},
            ],
          });
        }),
      );

      final trends = await service.getTopicKeywordTrends(
        ['https://openalex.org/T1'],
        ['https://openalex.org/keywords/computer-science'],
      );

      expect(trends['computer-science']!.map((trend) => trend.year), [
        2023,
        2024,
      ]);
      expect(requestedUrl!.queryParameters['group_by'], 'publication_year');
      expect(
        requestedUrl!.queryParameters['filter'],
        'primary_topic.id:T1,primary_location.source.type:journal,keywords.id:computer-science',
      );
    });

    test(
      'getKeywordTopAuthors groups selected keyword works by author',
      () async {
        Uri? requestedUrl;
        final service = OpenAlexService(
          minRequestInterval: Duration.zero,
          client: MockClient((request) async {
            requestedUrl = request.url;
            return _jsonResponse({
              'group_by': [
                {
                  'key': 'https://openalex.org/A1',
                  'key_display_name': 'Ada',
                  'count': 5,
                },
              ],
            });
          }),
        );

        final authors = await service.getKeywordTopAuthors([
          'https://openalex.org/T1',
        ], 'https://openalex.org/keywords/computer-science');

        expect(authors.single['name'], 'Ada');
        expect(
          requestedUrl!.queryParameters['group_by'],
          'authorships.author.id',
        );
        expect(
          requestedUrl!.queryParameters['filter'],
          'primary_topic.id:T1,primary_location.source.type:journal,keywords.id:computer-science',
        );
      },
    );

    test(
      'searchJournalSourcesByTopic can filter journals by multiple selected topics',
      () async {
        Uri? requestedUrl;
        final service = OpenAlexService(
          minRequestInterval: Duration.zero,
          client: MockClient((request) async {
            requestedUrl = request.url;
            return _jsonResponse({
              'group_by': [
                {
                  'key': 'https://openalex.org/S2',
                  'key_display_name': 'Multi Topic Journal',
                  'count': 20,
                },
              ],
            });
          }),
        );

        final result = await service.searchJournalSourcesByTopic(
          'Military topics',
          topicIds: ['https://openalex.org/T1', 'https://openalex.org/T2'],
        );

        expect(result['results'].single.name, 'Multi Topic Journal');
        expect(requestedUrl!.path, endsWith('/works'));
        expect(
          requestedUrl!.queryParameters['filter'],
          'primary_topic.id:T1|T2,primary_location.source.type:journal',
        );
      },
    );

    test('getJournalDetails normalizes full OpenAlex source URLs', () async {
      Uri? requestedUrl;
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          requestedUrl = request.url;
          return _jsonResponse({
            'id': 'https://openalex.org/S123',
            'display_name': 'Normalized Journal',
            'works_count': 7,
            'cited_by_count': 11,
          });
        }),
      );

      final journal = await service.getJournalDetails(
        'https://openalex.org/S123',
      );

      expect(journal.name, 'Normalized Journal');
      expect(requestedUrl!.path, endsWith('/sources/S123'));
    });

    test(
      'getWorksByJournal builds journal, year, citation and search filters',
      () async {
        Uri? requestedUrl;
        final service = OpenAlexService(
          minRequestInterval: Duration.zero,
          client: MockClient((request) async {
            requestedUrl = request.url;
            return _jsonResponse({
              'meta': {'count': 1},
              'results': [_workJson()],
            });
          }),
        );

        final result = await service.getWorksByJournal(
          'https://openalex.org/S123',
          page: 2,
          perPage: 5,
          search: 'impact',
          topicIds: ['https://openalex.org/T1', 'T2'],
          year: 2025,
          minCitations: 10,
          sortField: 'cited_by_count',
        );

        expect(result['total_count'], 1);
        expect(result['results'].single.title, 'A test work');
        expect(
          requestedUrl!.queryParameters['filter'],
          'primary_location.source.id:S123,publication_year:2025,cited_by_count:>10,primary_topic.id:T1|T2',
        );
        expect(requestedUrl!.queryParameters['search'], 'impact');
        expect(requestedUrl!.queryParameters['page'], '2');
        expect(requestedUrl!.queryParameters['per_page'], '5');
        expect(requestedUrl!.queryParameters['sort'], 'cited_by_count:desc');
      },
    );

    test(
      'getJournalYearlyTrend sorts grouped years and keeps topic scope',
      () async {
        Uri? requestedUrl;
        final service = OpenAlexService(
          minRequestInterval: Duration.zero,
          client: MockClient((request) async {
            requestedUrl = request.url;
            return _jsonResponse({
              'group_by': [
                {'key': '2025', 'count': 3},
                {'key': '2024', 'count': 2},
              ],
            });
          }),
        );

        final trends = await service.getJournalYearlyTrend(
          'S1',
          topicIds: ['T1', 'https://openalex.org/T2'],
        );

        expect(trends.map((trend) => trend.year), [2024, 2025]);
        expect(trends.map((trend) => trend.count), [2, 3]);
        expect(
          requestedUrl!.queryParameters['filter'],
          'primary_location.source.id:S1,primary_topic.id:T1|T2',
        );
      },
    );

    test(
      'getJournalTopTopics falls back to concepts when primary topics are empty',
      () async {
        var calls = 0;
        final service = OpenAlexService(
          minRequestInterval: Duration.zero,
          client: MockClient((request) async {
            calls++;
            if (calls == 1) {
              return _jsonResponse({'group_by': []});
            }
            return _jsonResponse({
              'group_by': [
                {
                  'key': 'https://openalex.org/C1',
                  'display_name': 'Bibliometrics',
                  'count': 9,
                },
              ],
            });
          }),
        );

        final topics = await service.getJournalTopTopics('S1');

        expect(topics.single['id'], 'C1');
        expect(topics.single['name'], 'Bibliometrics');
        expect(topics.single['filter_field'], 'concepts.id');
      },
    );

    test('getWorksByAuthor normalizes author URLs', () async {
      Uri? requestedUrl;
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          requestedUrl = request.url;
          return _jsonResponse({
            'meta': {'count': 1},
            'results': [_workJson()],
          });
        }),
      );

      final result = await service.getWorksByAuthor('https://openalex.org/A1');

      expect(result['total_count'], 1);
      expect(requestedUrl!.queryParameters['filter'], 'author.id:A1');
    });

    test('adds API key to requests when configured', () async {
      Uri? requestedUrl;
      final service = OpenAlexService(
        apiKey: 'demo-key',
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          requestedUrl = request.url;
          return _jsonResponse({'id': 'S1', 'display_name': 'API Key Journal'});
        }),
      );

      await service.getJournalDetails('S1');

      expect(requestedUrl!.queryParameters['api_key'], 'demo-key');
      expect(requestedUrl!.queryParameters.containsKey('mailto'), isFalse);
    });

    test('reuses cached responses for repeated identical requests', () async {
      var calls = 0;
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          calls++;
          return _jsonResponse({'id': 'S1', 'display_name': 'Cached Journal'});
        }),
      );

      await service.getJournalDetails('S1');
      await service.getJournalDetails('S1');

      expect(calls, 1);
    });

    test('deduplicates identical in-flight requests', () async {
      var calls = 0;
      final completer = Completer<http.Response>();
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) {
          calls++;
          return completer.future;
        }),
      );

      final first = service.getJournalDetails('S1');
      final second = service.getJournalDetails('S1');
      completer.complete(
        _jsonResponse({'id': 'S1', 'display_name': 'In Flight Journal'}),
      );

      final journals = await Future.wait([first, second]);

      expect(calls, 1);
      expect(journals.map((journal) => journal.name), [
        'In Flight Journal',
        'In Flight Journal',
      ]);
    });

    test('retries once after API 429 and then succeeds', () async {
      var calls = 0;
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        requestTimeout: const Duration(seconds: 1),
        client: MockClient((request) async {
          calls++;
          if (calls == 1) {
            return http.Response(
              '{"error":"too many requests"}',
              429,
              headers: {'retry-after': '0'},
            );
          }
          return _jsonResponse({
            'id': 'S1',
            'display_name': 'Recovered Journal',
          });
        }),
      );

      final journal = await service.getJournalDetails('S1');

      expect(calls, 2);
      expect(journal.name, 'Recovered Journal');
    });
  });
}

http.Response _jsonResponse(Map<String, dynamic> data) {
  return http.Response(
    jsonEncode(data),
    200,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, dynamic> _workJson() {
  return {
    'id': 'https://openalex.org/W1',
    'display_name': 'A test work',
    'publication_year': 2025,
    'publication_date': '2025-01-01',
    'cited_by_count': 12,
    'primary_location': {
      'source': {'display_name': 'Journal Analytics'},
    },
    'authorships': [
      {
        'author': {'id': 'A1', 'display_name': 'Ada'},
      },
    ],
  };
}
