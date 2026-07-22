import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/models/journal_model.dart';

void main() {
  group('Journal', () {
    test('parses nested source data and detailed OpenAlex fields', () {
      final journal = Journal.fromJson({
        'source': {
          'id': 'https://openalex.org/S999',
          'display_name': 'Nested Source Journal',
          'type': 'journal',
          'publisher': 'Nested Publisher',
          'homepage_url': 'https://journal.example',
          'issn': ['1234-5678', 9876],
          'alternate_titles': ['NSJ', 2026],
          'is_oa': true,
          'is_in_doaj': true,
          'apc_usd': 1200,
        },
        'works_count': 33,
        'cited_by_count': 44,
        'summary_stats': {
          'h_index': 15,
          'i10_index': 9,
          '2yr_mean_citedness': 3.25,
        },
        'counts_by_year': [
          {'year': 2026, 'works_count': 4, 'cited_by_count': 8},
        ],
      });

      expect(journal.id, 'https://openalex.org/S999');
      expect(journal.name, 'Nested Source Journal');
      expect(journal.publisher, 'Nested Publisher');
      expect(journal.homepageUrl, 'https://journal.example');
      expect(journal.issns, ['1234-5678', '9876']);
      expect(journal.alternateNames, ['NSJ', '2026']);
      expect(journal.isOa, isTrue);
      expect(journal.isInDoaj, isTrue);
      expect(journal.apcUsd, 1200);
      expect(journal.hIndex, 15);
      expect(journal.i10Index, 9);
      expect(journal.twoYearMeanCitedness, 3.25);
      expect(journal.countsByYear.single.year, 2026);
    });

    test('stores and restores local journal snapshots', () {
      final journal = Journal(
        id: 'https://openalex.org/S123',
        name: 'Journal of Testable Trends',
        type: 'journal',
        publisher: 'Open Research Press',
        worksCount: 42,
        citedByCount: 120,
        isOa: true,
        isInDoaj: true,
        hIndex: 12,
        i10Index: 8,
        twoYearMeanCitedness: 2.5,
        countsByYear: [
          JournalYearlyData(year: 2025, worksCount: 10, citedByCount: 30),
        ],
      );

      final restored = Journal.fromStoredJson(journal.toStoredJson());

      expect(restored.id, journal.id);
      expect(restored.name, journal.name);
      expect(restored.publisher, journal.publisher);
      expect(restored.worksCount, journal.worksCount);
      expect(restored.citedByCount, journal.citedByCount);
      expect(restored.isOa, isTrue);
      expect(restored.isInDoaj, isTrue);
      expect(restored.countsByYear, hasLength(1));
      expect(restored.countsByYear.first.year, 2025);
    });

    test('restores defaults from sparse stored data', () {
      final journal = Journal.fromStoredJson({});

      expect(journal.id, isEmpty);
      expect(journal.name, 'Unknown Source');
      expect(journal.worksCount, 0);
      expect(journal.citedByCount, 0);
      expect(journal.issns, isEmpty);
      expect(journal.alternateNames, isEmpty);
      expect(journal.countsByYear, isEmpty);
    });
  });
}
