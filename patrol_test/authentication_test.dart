import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

const runGoogleE2e = bool.fromEnvironment('RUN_GOOGLE_E2E');

void main() {
  patrolTest('Test Case 1 - Google Sign-In', ($) async {
    await pumpTestApp($);
    await openProfileTab($);

    if (runGoogleE2e) {
      await signInWithGoogleIfNeeded($);
      await waitForFinder($, find.byKey(const Key('sign_out_button')));
      expect(find.byKey(const Key('sign_out_button')), findsOneWidget);
    }

    await openHome($);
    expect(find.text('Explore Academic Insights'), findsOneWidget);
  });

  patrolTest('Test Case 11 - Logout to guest profile state', ($) async {
    await pumpTestApp($);
    await openProfileTab($);

    if (runGoogleE2e &&
        $.tester.any(find.byKey(const Key('google_sign_in_button')))) {
      await signInWithGoogleIfNeeded($);
    }

    if ($.tester.any(find.byKey(const Key('sign_out_button')))) {
      await $(#sign_out_button).tap();
      await waitForFinder($, find.byKey(const Key('google_sign_in_button')));
    }

    expect(find.text('Guest researcher'), findsOneWidget);
    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
  });
}
