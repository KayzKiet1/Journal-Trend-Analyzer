import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest(
    'Test Case 11 - Logout',
    timeout: const Timeout(Duration(seconds: 30)),
    ($) async {
      await pumpRealApp($);
      await openProfileTab($);
      await signInWithGoogleRequired($);
      await waitForFinder(
        $,
        find.byKey(const Key('sign_out_button')),
        timeout: const Duration(seconds: 20),
      );
      await $(#sign_out_button).scrollTo().tap();
      await waitForFinder(
        $,
        find.byKey(const Key('google_sign_in_button')),
        timeout: const Duration(seconds: 20),
      );
      expect(find.text('Guest researcher'), findsOneWidget);
    },
  );
}
