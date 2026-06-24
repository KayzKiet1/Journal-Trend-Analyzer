import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/main.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JournalTrendAnalyzerApp());

    // Check for App Bar title
    expect(find.text('Journal Trend Analyzer'), findsOneWidget);

    // Check for main headline
    expect(find.text('Explore Academic Insights'), findsOneWidget);

    // Check for search button (default category should be Sources/Journals now)
    expect(find.text('Search Sources'), findsOneWidget);

    // Check for hint text for journals
    expect(find.text('Search academic journals...'), findsOneWidget);
  });
}
