import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
      await pumpTestApp($);
      await openProfileTab($);
      if (runGoogleE2e) {
        await signInWithGoogleIfNeeded($);
        await waitForFinder(
          $,
          find.byKey(const Key('sign_out_button')),
          timeout: const Duration(seconds: 20),
        );
      }

      await expandProfileSection($, 'Research Trend PDF');
      await $(#export_pdf_button).scrollTo();
      expect(find.text('Research Trend PDF'), findsOneWidget);
      expect(find.text(defaultTopic), findsWidgets);

      if (!runGoogleE2e) {
        expect(find.text('Required for Storage'), findsOneWidget);
      }

      if (runFirebaseE2e && runGoogleE2e) {
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
