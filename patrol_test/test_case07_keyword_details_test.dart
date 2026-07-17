import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest(
    'Test Case 7 - Keyword Details',
    timeout: const Timeout(Duration(seconds: 30)),
    ($) async {
      await pumpTestApp($);
      await openKeywordsTab($);
      await waitForFinder(
        $,
        find.byKey(const Key('keyword_card_1')),
        timeout: const Duration(seconds: 10),
      );
      await $(#keyword_card_1).scrollTo().tap();
      await waitForFinder(
        $,
        find.byKey(const Key('keyword_detail_content')),
        timeout: const Duration(seconds: 25),
      );
      expect(find.text('machine learning'), findsWidgets);

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
