import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/models/journal_model.dart';

void main() {
  group('Journal', () {
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
  });
}
