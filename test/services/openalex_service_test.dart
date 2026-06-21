import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  late OpenAlexService service;
  late MockClient mockClient;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockClient = MockClient();
    service = OpenAlexService(client: mockClient);
  });

  group('OpenAlexService Tests', () {
    test('searchWorks returns data on 200', () async {
      final responseData = {
        'results': [
          {'id': 'W1', 'display_name': 'Work 1', 'publication_year': 2023}
        ],
        'meta': {'count': 1}
      };

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(responseData), 200),
      );

      final result = await service.searchWorks('test');
      expect(result['results'].length, 1);
      expect(result['total_count'], 1);
    });

    test('searchWorks throws on error', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('Error', 500),
      );

      expect(() => service.searchWorks('test'), throwsException);
    });

    test('getYearlyTrend returns sorted data', () async {
      final responseData = {
        'group_by': [
          {'key': '2022', 'count': 10},
          {'key': '2021', 'count': 5}
        ]
      };

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(responseData), 200),
      );

      final result = await service.getYearlyTrend('test');
      expect(result.length, 2);
      expect(result[0].year, 2021);
      expect(result[1].year, 2022);
    });

    test('getTopKeywords returns limited data', () async {
       final responseData = {
        'group_by': [
          {'display_name': 'Keyword 1', 'count': 10},
          {'display_name': 'Unknown', 'count': 5},
          {'display_name': '', 'count': 2}
        ]
      };

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(responseData), 200),
      );

      final result = await service.getTopKeywords('test');
      expect(result.length, 1);
      expect(result[0]['name'], 'Keyword 1');
    });
    test('getTopJournals returns data', () async {
      final responseData = {
        'group_by': [{'display_name': 'Journal 1', 'count': 5}]
      };
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(responseData), 200),
      );
      final result = await service.getTopJournals('test');
      expect(result.length, 1);
      expect(result[0]['name'], 'Journal 1');
    });

    test('getTopAuthorsByTopic returns data', () async {
      final responseData = {
        'group_by': [{'display_name': 'Author 1', 'count': 5}]
      };
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(responseData), 200),
      );
      final result = await service.getTopAuthorsByTopic('test');
      expect(result.length, 1);
    });

    test('getCountryOutput returns data', () async {
      final responseData = {
        'group_by': [{'key': 'VN', 'display_name': 'Vietnam', 'count': 10}]
      };
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(responseData), 200),
      );
      final result = await service.getCountryOutput('test');
      expect(result.length, 1);
      expect(result[0]['country_code'], 'VN');
    });

    test('getInstitutionRanking returns data', () async {
      final responseData = {
        'group_by': [{'display_name': 'Inst 1', 'count': 10}]
      };
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(responseData), 200),
      );
      final result = await service.getInstitutionRanking('test');
      expect(result.length, 1);
    });

    test('getQuartileDistribution returns real calculation', () async {
      final responseData = {
        'results': [
          {'citation_normalized_percentile': {'value': 80}}, // Q1
          {'citation_normalized_percentile': {'value': 60}}, // Q2
          {'citation_normalized_percentile': {'value': 30}}, // Q3
          {'citation_normalized_percentile': {'value': 10}}, // Q4
        ]
      };
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(responseData), 200),
      );
      final result = await service.getQuartileDistribution('test');
      expect(result.length, 4);
      expect(result[0]['name'], contains('Q1'));
      expect(result[0]['count'], 1);
      expect(result[0]['percentage'], 25);
    });
  });
}
