import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/widgets/publication_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest(
    'Test Case 2 - Topic Search',
    timeout: const Timeout(Duration(seconds: 45)),
    ($) async {
      await pumpTestApp($);
      await openHome($);

      await searchTopicAndShowPublications($);

      expect(find.text('TOPIC RESEARCH OVERVIEW'), findsOneWidget);
      expect(find.text('MOST INFLUENTIAL PUBLICATIONS'), findsOneWidget);
      expect(find.byType(PublicationCard), findsOneWidget);
    },
  );

  patrolTest(
    'Test Case 3 - Publication Details',
    timeout: const Timeout(Duration(seconds: 45)),
    ($) async {
      await pumpTestApp($);
      await openHome($);

      await searchTopicAndShowPublications($);
      await $(PublicationCard).at(0).scrollTo().tap();
      await waitForFinder(
        $,
        find.byKey(const Key('publication_detail_content')),
        timeout: const Duration(seconds: 10),
      );

      expect(
        find.text('Artificial intelligence in research discovery'),
        findsOneWidget,
      );
      expect(find.textContaining('Journal of AI Research'), findsWidgets);
      expect(
        find.textContaining('fixture publication verifies'),
        findsOneWidget,
      );
    },
  );
}
