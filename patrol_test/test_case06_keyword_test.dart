import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest(
    'Test Case 6 - Keywords Navigation',
    timeout: const Timeout(Duration(seconds: 30)),
    ($) async {
      await pumpTestApp($);
      await openKeywordsTab($);
      await waitForFinder(
        $,
        find.text('Keyword Frequency'),
        timeout: const Duration(seconds: 10),
      );
      await waitForFinder(
        $,
        find.byKey(const Key('keyword_card_1')),
        timeout: const Duration(seconds: 10),
      );
      expect(find.text('Keyword Insights'), findsOneWidget);
      expect(find.text('machine learning'), findsWidgets);
    },
  );
}
