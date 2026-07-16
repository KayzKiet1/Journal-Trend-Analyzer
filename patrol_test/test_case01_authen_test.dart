import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest(
    'Test Case 1 - Google Sign-In',
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
      expect(find.text('Explore Academic Insights'), findsOneWidget);
    },
  );
}
