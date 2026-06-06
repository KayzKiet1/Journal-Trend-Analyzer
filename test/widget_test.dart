import 'package:flutter_test/flutter_test.dart';

import 'package:journal_trend_analyzer/main.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JournalTrendAnalyzerApp());

    expect(find.text('Journal Trend Analyzer'), findsOneWidget);
    expect(find.text('Analyze Research Trends'), findsOneWidget);
    expect(find.text('Search Publications'), findsOneWidget);
    expect(find.text('e.g., Artificial Intelligence'), findsOneWidget);
  });
}
