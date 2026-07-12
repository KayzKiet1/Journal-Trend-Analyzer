import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('Test Case 6 - Keywords Navigation', ($) async {
    await pumpTestApp($);
    await openKeywordsTab($);

    expect(find.text('Keyword Intelligence'), findsOneWidget);
    expect(find.text('Keyword Occurrences'), findsOneWidget);
    expect(find.text('machine learning'), findsOneWidget);
  });

  patrolTest('Test Case 7 - Keyword Details', ($) async {
    await pumpTestApp($);
    await openKeywordsTab($);

    await $(#keyword_card_1).scrollTo().tap();
    await waitForFinder($, find.byKey(const Key('keyword_detail_content')));

    expect(find.text('Keyword Analysis'), findsOneWidget);
    expect(find.text('Analysis Scope'), findsOneWidget);
    expect(find.text('Related Publications'), findsOneWidget);
  });
}
