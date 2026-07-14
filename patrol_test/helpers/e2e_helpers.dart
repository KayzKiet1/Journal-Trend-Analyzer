import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/viewmodels/publication_view_model.dart';
import 'package:journal_trend_analyzer/firebase/firebase_initializer.dart';
import 'package:journal_trend_analyzer/main.dart';
import 'package:journal_trend_analyzer/models/author_model.dart';
import 'package:journal_trend_analyzer/models/journal_model.dart';
import 'package:journal_trend_analyzer/models/publication_model.dart';
import 'package:journal_trend_analyzer/models/trend_data_model.dart';
import 'package:journal_trend_analyzer/screens/main_screen.dart';
import 'package:patrol/patrol.dart';
import 'package:provider/provider.dart' show Provider;

const defaultTopic = 'Artificial Intelligence';
const googleTestAccount = String.fromEnvironment(
  'GOOGLE_TEST_ACCOUNT',
  defaultValue: 'vokiet2004t@gmail.com',
);
const shortTimeout = Duration(seconds: 8);

Future<void> pumpTestApp(PatrolIntegrationTester $) async {
  await initializeFirebase();
  await $.pumpWidgetAndSettle(const JournalTrendAnalyzerApp());
  await waitForFinder($, find.text('Journal Trend Analyzer'));
  seedFixtures($);
  await $.pumpAndSettle();
}

PublicationViewModel controllerOf(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byType(MainScreen));
  return Provider.of<PublicationViewModel>(context, listen: false);
}

void seedFixtures(PatrolIntegrationTester $) {
  // ignore: invalid_use_of_visible_for_testing_member
  controllerOf($).seedE2eFixtures(
    topic: defaultTopic,
    topicIds: const ['T123'],
    publications: [
      Publication(
        id: 'W1',
        title: 'Artificial intelligence in research discovery',
        publicationYear: 2026,
        publicationDate: '2026-01-10',
        citedByCount: 128,
        journalId: 'S1',
        journalName: 'Journal of AI Research',
        authors: [Author(id: 'A1', name: 'Ada Lovelace')],
        doi: 'https://doi.org/10.0000/e2e-ai',
        abstractText:
            'This fixture publication verifies the publication detail workflow.',
        topics: const ['Artificial Intelligence'],
      ),
    ],
    trends: [
      TrendData(year: 2024, count: 12),
      TrendData(year: 2025, count: 20),
      TrendData(year: 2026, count: 31),
    ],
    topAuthors: const {'Ada Lovelace': 1},
    topJournals: const {'Journal of AI Research': 1},
    journals: [
      Journal(
        id: 'S1',
        name: 'Journal of AI Research',
        type: 'journal',
        publisher: 'E2E Publishing',
        worksCount: 240,
        citedByCount: 1800,
        homepageUrl: 'https://example.com/jair',
        issns: const ['1234-5678'],
        hIndex: 42,
        i10Index: 80,
        countsByYear: [
          JournalYearlyData(year: 2024, worksCount: 50, citedByCount: 300),
          JournalYearlyData(year: 2025, worksCount: 80, citedByCount: 600),
          JournalYearlyData(year: 2026, worksCount: 110, citedByCount: 900),
        ],
      ),
    ],
    keywords: const [
      {'id': 'K1', 'name': 'machine learning', 'count': 42},
      {'id': 'K2', 'name': 'research analytics', 'count': 28},
    ],
  );
}

Future<void> waitForFinder(
  PatrolIntegrationTester $,
  Finder finder, {
  Duration timeout = shortTimeout,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await $.pump(const Duration(milliseconds: 150));
    if ($.tester.any(finder)) return;
  }
  expect(finder, findsOneWidget);
}

Future<void> openHome(PatrolIntegrationTester $) async {
  if ($.tester.any(find.text('Explore Academic Insights'))) return;

  await $(#nav_home).tap();
  await waitForFinder($, find.text('Explore Academic Insights'));
}

Future<void> openJournalsTab(PatrolIntegrationTester $) async {
  await $(#nav_journals).tap();
  await waitForFinder($, find.text('Discover Journals'));
}

Future<void> openKeywordsTab(PatrolIntegrationTester $) async {
  await $(#nav_keywords).tap();
  await waitForFinder($, find.text('Search Keywords'));
}

Future<void> openProfileTab(PatrolIntegrationTester $) async {
  await $(#nav_profile).tap();
  await waitForFinder($, find.text('Profile'));
}

Future<void> searchTopicAndShowPublications(PatrolIntegrationTester $) async {
  await $(#home_topic_search_field).enterText(defaultTopic);
  await $(#home_search_button).tap();
  await waitForFinder(
    $,
    find.text('MOST INFLUENTIAL PUBLICATIONS'),
    timeout: const Duration(seconds: 10),
  );
}

Future<void> signInWithGoogleIfNeeded(PatrolIntegrationTester $) async {
  if (!$.tester.any(find.byKey(const Key('google_sign_in_button')))) return;

  await $(#google_sign_in_button).tap();
  await chooseGoogleAccountIfVisible($);
  await waitForFinder(
    $,
    find.byKey(const Key('sign_out_button')),
    timeout: const Duration(seconds: 20),
  );
}

Future<void> chooseGoogleAccountIfVisible(PatrolIntegrationTester $) async {
  if (googleTestAccount.isEmpty) return;

  final accountSelector = Selector(textContains: googleTestAccount);
  try {
    await $.platform.mobile.waitUntilVisible(
      accountSelector,
      timeout: const Duration(seconds: 10),
    );
    await $.platform.mobile.tap(
      accountSelector,
      timeout: const Duration(seconds: 10),
    );
  } catch (_) {
    // The chooser is skipped when the emulator already has an active session.
  }
}
