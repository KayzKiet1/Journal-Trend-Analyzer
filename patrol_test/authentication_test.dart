import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

const runGoogleE2e = bool.fromEnvironment('RUN_GOOGLE_E2E', defaultValue: true);

void main() {
  patrolTest('Test Case 1 - Google Sign-In', ($) async {
    await pumpTestApp($);
    await openProfileTab($);

    if (runGoogleE2e) {
      await signInWithGoogleIfNeeded($);
      await waitForFinder($, find.byKey(const Key('sign_out_button')));
      expect(find.textContaining(googleTestAccount), findsWidgets);
    }

    expect(find.text('Profile'), findsOneWidget);
    expect(
      $.tester.any(find.byKey(const Key('google_sign_in_button'))) ||
          $.tester.any(find.byKey(const Key('sign_out_button'))),
      isTrue,
    );
  });

  patrolTest('Test Case 11 - Logout', ($) async {
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
