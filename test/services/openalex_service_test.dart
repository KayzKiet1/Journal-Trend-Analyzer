import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';

void main() {
  setUp(OpenAlexService.resetForTesting);

  group('OpenAlexService', () {
    test('searchSources filters source results to journals', () async {
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

      final result = await service.searchSources('analytics');

      expect(result['total_count'], 1);
      expect(result['results'].single.name, 'Journal Analytics');
      expect(requestedUrl!.queryParameters['filter'], 'type:journal');
      expect(requestedUrl!.queryParameters['search'], 'analytics');
    });

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
          year: 2025,
          minCitations: 10,
          sortField: 'cited_by_count',
        );

        expect(result['total_count'], 1);
        expect(result['results'].single.title, 'A test work');
        expect(
          requestedUrl!.queryParameters['filter'],
          'primary_location.source.id:S123,publication_year:2025,cited_by_count:>10',
        );
        expect(requestedUrl!.queryParameters['search'], 'impact');
        expect(requestedUrl!.queryParameters['page'], '2');
        expect(requestedUrl!.queryParameters['per_page'], '5');
        expect(requestedUrl!.queryParameters['sort'], 'cited_by_count:desc');
      },
    );

    test('getJournalYearlyTrend sorts grouped years', () async {
      final service = OpenAlexService(
        minRequestInterval: Duration.zero,
        client: MockClient((request) async {
          return _jsonResponse({
            'group_by': [
              {'key': '2025', 'count': 3},
              {'key': '2024', 'count': 2},
            ],
          });
        }),
      );

      final trends = await service.getJournalYearlyTrend('S1');

      expect(trends.map((trend) => trend.year), [2024, 2025]);
      expect(trends.map((trend) => trend.count), [2, 3]);
    });

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
