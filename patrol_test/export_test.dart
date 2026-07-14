import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

const runFirebaseE2e = bool.fromEnvironment('RUN_FIREBASE_E2E');

void main() {
  patrolTest(
    'Test Case 9 - PDF Export',
    timeout: const Timeout(Duration(minutes: 3)),
    ($) async {
      await pumpTestApp($);
      await openHome($);
      await searchTopicAndShowPublications($);
      await openProfileTab($);

      await $(#export_pdf_button).scrollTo();
      expect(find.text('Research Trend PDF'), findsOneWidget);
      expect(find.text('Google sign-in'), findsOneWidget);
      expect(find.text('HOME dashboard data'), findsOneWidget);
      expect(find.text('Remote Config export flag'), findsOneWidget);

      if (runFirebaseE2e) {
        await signInWithGoogleIfNeeded($);
        await $(#export_pdf_button).scrollTo();
        await $(#export_pdf_button).tap();
        await waitForFinder(
          $,
          find.text('PDF report exported and uploaded.'),
          timeout: const Duration(seconds: 60),
        );
        await openProfileTab($);
        expect(find.text('FIREBASE STORAGE URL'), findsOneWidget);
      }
    },
  );
}
