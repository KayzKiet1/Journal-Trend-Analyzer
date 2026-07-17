import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest(
    'Test Case 10 - Remote Config',
    timeout: const Timeout(Duration(seconds: 30)),
    ($) async {
      await pumpRealApp($);
      await openProfileTab($);
      await expandProfileSection($, 'Firebase Remote Config');
      await $(#fetch_remote_config_button).scrollTo();
      await waitForFinder(
        $,
        find.text('Journal cards limit'),
        timeout: const Duration(seconds: 20),
      );
      await $(#fetch_remote_config_button).tap();
      expect(find.text('Journal cards limit'), findsOneWidget);
      expect(find.text('Keyword rows limit'), findsOneWidget);
      expect(find.text('PDF export feature'), findsOneWidget);
    },
  );
}
