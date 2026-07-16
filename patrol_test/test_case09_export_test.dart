import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/widgets/publication_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

const runFirebaseE2e = bool.fromEnvironment(
  'RUN_FIREBASE_E2E',
  defaultValue: true,
);

void main() {
  patrolTest(
    'Test Case 9 - PDF Export',
    timeout: const Timeout(Duration(seconds: 30)),
    ($) async {
      await pumpRealApp($);
      await openProfileTab($);
      await signInWithGoogleIfNeeded($);
      await waitForFinder(
        $,
        find.byKey(const Key('sign_out_button')),
        timeout: const Duration(seconds: 20),
      );
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
      await openProfileTab($);
      await $(#export_pdf_button).scrollTo();
      expect(find.text('Research Trend PDF'), findsOneWidget);
      if (runFirebaseE2e) {
        await $(#export_pdf_button).tap();
        await waitForFinder(
          $,
          find.text('PDF report exported and uploaded.'),
          timeout: const Duration(seconds: 25),
        );
        expect(find.text('FIREBASE STORAGE URL'), findsOneWidget);
      }
    },
  );
}
