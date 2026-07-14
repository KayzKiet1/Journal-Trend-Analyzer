import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

const runFirebaseE2e = bool.fromEnvironment('RUN_FIREBASE_E2E');

void main() {
  patrolTest('Test Case 10 - Remote Config', ($) async {
    await pumpTestApp($);
    await openProfileTab($);

    await $(#fetch_remote_config_button).scrollTo();
    if (runFirebaseE2e) {
      await $(#fetch_remote_config_button).tap();
    }
    await waitForFinder($, find.text('Firebase Remote Config'));

    expect(find.text('Journal cards limit'), findsOneWidget);
    expect(find.text('Keyword rows limit'), findsOneWidget);
    expect(find.text('PDF export feature'), findsOneWidget);
    expect(find.textContaining('Status:'), findsOneWidget);
  });
}
