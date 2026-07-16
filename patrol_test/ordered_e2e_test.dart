import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/screens/journals/widgets/list/journal_card.dart';
import 'package:journal_trend_analyzer/widgets/publication_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

const e2eTopic = 'Artificial intelligence';
const caseTimeout = Timeout(Duration(seconds: 30));
const runFirebaseE2e = bool.fromEnvironment(
  'RUN_FIREBASE_E2E',
  defaultValue: true,
);

void patrolCase(
  int number,
  String name,
  Future<void> Function(PatrolIntegrationTester $) body,
) {
  final label = 'Test Case $number - $name';
  patrolTest(label, timeout: caseTimeout, ($) async {
    // ignore: avoid_print
    print('RUN $label');
    try {
      await body($);
      // ignore: avoid_print
      print('✓ $label');
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print('✗ $label');
      // ignore: avoid_print
      print(error);
      // ignore: avoid_print
      print(stackTrace);
      rethrow;
    }
  });
}

Future<void> ensureSignedIn(PatrolIntegrationTester $) async {
  await pumpRealApp($);
  await openProfileTab($);
  await signInWithGoogleIfNeeded($);
  await waitForFinder(
    $,
    find.byKey(const Key('sign_out_button')),
    timeout: const Duration(seconds: 20),
  );
}

Future<void> searchHomeTopic(PatrolIntegrationTester $) async {
  await openHome($);
  await $(#home_topic_search_field).enterText(e2eTopic);
  await $(#home_search_button).tap();
  await waitForFinder(
    $,
    find.text('MOST INFLUENTIAL PUBLICATIONS'),
    timeout: const Duration(seconds: 25),
  );
  await waitForFinder(
    $,
    find.byType(PublicationCard),
    timeout: const Duration(seconds: 10),
  );
}

Future<void> popDetailScreen(PatrolIntegrationTester $) async {
  final backButton = find.byTooltip('Back');
  if (backButton.evaluate().isNotEmpty) {
    await $.tester.tap(backButton.first);
  } else {
    await $.platform.android.pressBack();
  }
  await $.pumpAndSettle();
}

void main() {
  patrolCase(1, 'Google Sign-In', ($) async {
    await ensureSignedIn($);
    await openHome($);
    expect(find.text('Explore Academic Insights'), findsOneWidget);
  });

  patrolCase(2, 'Topic Search', ($) async {
    await pumpRealApp($);
    await searchHomeTopic($);
    expect(find.text('TOPIC RESEARCH OVERVIEW'), findsOneWidget);
  });

  patrolCase(3, 'Publication Details', ($) async {
    await pumpRealApp($);
    await searchHomeTopic($);
    await $(PublicationCard).at(0).scrollTo().tap();
    await waitForFinder(
      $,
      find.byKey(const Key('publication_detail_content')),
      timeout: const Duration(seconds: 15),
    );
    await popDetailScreen($);
  });

  patrolCase(4, 'Journals Navigation', ($) async {
    await pumpRealApp($);
    await openJournalsTab($);
    await waitForFinder(
      $,
      find.byType(JournalCard),
      timeout: const Duration(seconds: 25),
    );
    expect(find.text('SEARCH JOURNAL SOURCES'), findsOneWidget);
    expect(find.textContaining('loaded'), findsWidgets);
  });

  patrolCase(5, 'Journal Details', ($) async {
    await pumpRealApp($);
    await openJournalsTab($);
    await waitForFinder(
      $,
      find.byType(JournalCard),
      timeout: const Duration(seconds: 25),
    );
    await $(JournalCard).at(0).scrollTo().tap();
    await waitForFinder(
      $,
      find.byKey(const Key('journal_detail_content')),
      timeout: const Duration(seconds: 25),
    );
    await popDetailScreen($);
  });

  patrolCase(6, 'Keywords Navigation', ($) async {
    await pumpRealApp($);
    await searchHomeTopic($);
    await openKeywordsTab($);
    await waitForFinder(
      $,
      find.text('Keyword Occurrences'),
      timeout: const Duration(seconds: 25),
    );
    await waitForFinder(
      $,
      find.byKey(const Key('keyword_card_1')),
      timeout: const Duration(seconds: 10),
    );
    expect(find.text('Search Keywords'), findsOneWidget);
  });

  patrolCase(7, 'Keyword Details', ($) async {
    await pumpRealApp($);
    await searchHomeTopic($);
    await openKeywordsTab($);
    await waitForFinder(
      $,
      find.byKey(const Key('keyword_card_1')),
      timeout: const Duration(seconds: 25),
    );
    await $(#keyword_card_1).scrollTo().tap();
    await waitForFinder(
      $,
      find.byKey(const Key('keyword_detail_content')),
      timeout: const Duration(seconds: 25),
    );
    await popDetailScreen($);
  });

  patrolCase(8, 'Profile Navigation', ($) async {
    await ensureSignedIn($);
    expect(find.byKey(const Key('profile_content')), findsOneWidget);
    expect(find.byKey(const Key('sign_out_button')), findsOneWidget);
    expect(find.text('Receive notifications'), findsOneWidget);
  });

  patrolCase(9, 'PDF Export', ($) async {
    await ensureSignedIn($);
    await searchHomeTopic($);
    await openProfileTab($);
    await $(#export_pdf_button).scrollTo();
    expect(find.text('Research Trend PDF'), findsOneWidget);
    if (runFirebaseE2e) {
      await $(#export_pdf_button).tap();
      await waitForFinder(
        $,
        find.text('PDF report exported and uploaded.'),
        timeout: const Duration(seconds: 25),
      );
      expect(find.text('FIREBASE STORAGE URL'), findsOneWidget);
    }
  });

  patrolCase(10, 'Remote Config', ($) async {
    await pumpRealApp($);
    await openProfileTab($);
    await $(#fetch_remote_config_button).scrollTo();
    await $(#fetch_remote_config_button).tap();
    await waitForFinder(
      $,
      find.text('Firebase Remote Config'),
      timeout: const Duration(seconds: 20),
    );
    expect(find.text('Journal cards limit'), findsOneWidget);
    expect(find.text('Keyword rows limit'), findsOneWidget);
    expect(find.text('PDF export feature'), findsOneWidget);
  });

  patrolCase(11, 'Logout', ($) async {
    await ensureSignedIn($);
    await $(#sign_out_button).scrollTo().tap();
    await waitForFinder(
      $,
      find.byKey(const Key('google_sign_in_button')),
      timeout: const Duration(seconds: 20),
    );
    expect(find.text('Guest researcher'), findsOneWidget);
  });
}
