import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/widgets/publication_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest(
    'Test Case 6 - Keywords Navigation',
    timeout: const Timeout(Duration(seconds: 30)),
    ($) async {
      await pumpRealApp($);
      await openHome($);
      await $(#home_topic_search_field).enterText('Artificial intelligence');
      await $(#home_search_button).tap();
      await waitForFinder(
        $,
        find.text('MOST INFLUENTIAL PUBLICATIONS'),
        timeout: const Duration(seconds: 25),
      );
      await waitForFinder(
        $,
        find.byType(PublicationCard),
        timeout: const Duration(seconds: 10),
      );
      await openKeywordsTab($);
      await waitForFinder(
        $,
        find.text('Keyword Frequency'),
        timeout: const Duration(seconds: 25),
      );
      await waitForFinder(
        $,
        find.byKey(const Key('keyword_card_1')),
        timeout: const Duration(seconds: 10),
      );
      expect(find.text('Keyword Insights'), findsOneWidget);
    },
  );
}
