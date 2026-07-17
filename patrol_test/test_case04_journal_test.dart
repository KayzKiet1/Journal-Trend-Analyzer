import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/screens/journals/widgets/list/journal_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest(
    'Test Case 4 - Journals Navigation',
    timeout: const Timeout(Duration(seconds: 30)),
    ($) async {
      await pumpRealApp($);
      await openJournalsTab($);
      await waitForFinder(
        $,
        find.byType(JournalCard),
        timeout: const Duration(seconds: 25),
      );
      expect(find.text('SEARCH JOURNAL SOURCES'), findsOneWidget);
      expect(find.textContaining('loaded'), findsWidgets);
    },
  );
}
