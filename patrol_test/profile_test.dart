import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('Test Case 8 - Profile Navigation', ($) async {
    await pumpTestApp($);
    await openProfileTab($);

    expect(find.byKey(const Key('profile_content')), findsOneWidget);
    expect(find.text('Guest researcher'), findsOneWidget);
    expect(find.text('REPORT EXPORT'), findsOneWidget);
    expect(find.text('REMOTE CONFIG'), findsOneWidget);
  });
}
