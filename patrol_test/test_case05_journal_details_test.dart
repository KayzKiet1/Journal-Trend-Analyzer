import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/screens/journals/widgets/list/journal_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest(
    'Test Case 5 - Journal Details',
    timeout: const Timeout(Duration(seconds: 30)),
    ($) async {
      await pumpRealApp($);
      await openJournalsTab($);
      await waitForFinder(
        $,
        find.byType(JournalCard),
        timeout: const Duration(seconds: 25),
      );
      await $(JournalCard).at(0).scrollTo().tap();
      await waitForFinder(
        $,
        find.byKey(const Key('journal_detail_content')),
        timeout: const Duration(seconds: 25),
      );

      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await $.tester.tap(backButton.first);
      } else {
        await $.platform.android.pressBack();
      }
      await $.pumpAndSettle();
    },
  );
}
