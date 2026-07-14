import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('Test Case 4 - Journals Navigation', ($) async {
    await pumpTestApp($);
    await openJournalsTab($);

    expect(find.text('SEARCH JOURNAL SOURCES'), findsOneWidget);
    expect(
      find.textContaining('Showing popular journal sources'),
      findsOneWidget,
    );
    expect(find.text('Journal of AI Research'), findsOneWidget);
    expect(find.textContaining('publications'), findsWidgets);
  });

  patrolTest('Test Case 5 - Journal Details', ($) async {
    await pumpTestApp($);
    await openJournalsTab($);

    await $('Details').at(0).scrollTo().tap();
    await waitForFinder($, find.byKey(const Key('journal_detail_content')));

    expect(find.text('Key Metrics'), findsOneWidget);
    expect(find.text('Total Publications'), findsWidgets);
    expect(find.text('Journal Metadata'), findsOneWidget);
  });
}
