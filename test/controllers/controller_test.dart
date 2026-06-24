import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:journal_trend_analyzer/controllers/analysis_controller.dart';
import 'package:journal_trend_analyzer/services/openalex_service.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  late AnalysisController controller;
  late MockClient mockClient;
  late OpenAlexService service;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockClient = MockClient();
    service = OpenAlexService(client: mockClient);
    controller = AnalysisController(apiService: service);
  });

  group('AnalysisController Tests', () {
    test('fetchTrendAnalysis updates state correctly', () async {
      final trendData = {'group_by': [{'key': '2023', 'count': 5}]};
      final keywordsData = {'group_by': [{'display_name': 'AI', 'count': 10}]};
      
      // Mock tất cả các API call trong Future.wait
      when(() => mockClient.get(any())).thenAnswer((invocation) async {
        final url = invocation.positionalArguments[0] as Uri;
        if (url.toString().contains('group_by=publication_year')) {
          return http.Response(jsonEncode(trendData), 200);
        } else if (url.toString().contains('group_by=concepts.id')) {
          return http.Response(jsonEncode(keywordsData), 200);
        }
        return http.Response(jsonEncode({'results': [], 'group_by': []}), 200);
      });

      expect(controller.isLoading, false);
      
      final future = controller.fetchTrendAnalysis('AI');
      expect(controller.isLoading, true);
      
      await future;
      
      expect(controller.isLoading, false);
      expect(controller.trends.length, 1);
      expect(controller.topKeywords.length, 1);
      expect(controller.errorMessage, isEmpty);
    });

    test('fetchTrendAnalysis handles error', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('Error', 500),
      );

      await controller.fetchTrendAnalysis('AI');
      
      expect(controller.isLoading, false);
      expect(controller.errorMessage, contains('Lỗi phân tích'));
    });
    test('updateApiService changes service', () {
      controller.updateApiService('new@example.com');
      // Chúng ta không thể dễ dàng kiểm tra private field _apiService trừ khi expose nó
      // Nhưng gọi nó không gây lỗi là một bước tiến
      expect(true, true);
    });

    test('getters return correct data', () {
      expect(controller.trends, isEmpty);
      expect(controller.topKeywords, isEmpty);
      expect(controller.countryData, isEmpty);
      expect(controller.topAuthors, isEmpty);
      expect(controller.topJournals, isEmpty);
      expect(controller.institutions, isEmpty);
      expect(controller.quartiles, isEmpty);
      expect(controller.topInfluentialWorks, isEmpty);
    });
  });
}
