import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/models/trend_data_model.dart';
import 'package:journal_trend_analyzer/widgets/year_trend_chart.dart';
import 'package:journal_trend_analyzer/widgets/horizontal_bar_chart.dart';
import 'package:journal_trend_analyzer/widgets/country_output_map.dart';

void main() {
  group('Chart Widget Tests', () {
    testWidgets('YearTrendChart displays data', (WidgetTester tester) async {
      final trends = [TrendData(year: 2023, count: 10)];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: YearTrendChart(trends: trends)),
      ));
      expect(find.text('Số lượng bài báo theo năm'), findsOneWidget);
    });

    testWidgets('HorizontalBarChart displays title and items', (WidgetTester tester) async {
      final data = [{'name': 'Item 1', 'count': 5}];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: HorizontalBarChart(data: data, title: 'Test Title')),
      ));
      expect(find.text('TEST TITLE'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('CountryOutputList displays data', (WidgetTester tester) async {
      final countries = [{'name': 'Vietnam', 'country_code': 'VN', 'count': 100}];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CountryOutputList(countries: countries)),
      ));
      expect(find.text('12. SẢN LƯỢNG NGHIÊN CỨU THEO QUỐC GIA'), findsOneWidget);
      expect(find.text('Vietnam (VN)'), findsOneWidget);
    });
  });
}
