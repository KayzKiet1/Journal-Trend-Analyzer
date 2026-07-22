import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/models/author_model.dart';
import 'package:journal_trend_analyzer/models/publication_model.dart';
import 'package:journal_trend_analyzer/utils/abstract_parser.dart';
import 'package:journal_trend_analyzer/utils/analysis_helper.dart';

void main() {
  group('AbstractParser', () {
    test('rebuilds abstract text from inverted index', () {
      final text = AbstractParser.parseInvertedIndex({
        'OpenAlex': [0],
        'journal': [1],
        'trends': [2],
      });

      expect(text, 'OpenAlex journal trends');
    });

    test('returns fallback for empty abstract data', () {
      expect(AbstractParser.parseInvertedIndex(null), 'No abstract available.');
      expect(AbstractParser.parseInvertedIndex({}), 'No abstract available.');
    });

    test('skips missing positions when rebuilding text', () {
      final text = AbstractParser.parseInvertedIndex({
        'first': [0],
        'third': [2],
      });

      expect(text, 'first third');
    });

    test('returns parsing error when positions are malformed', () {
      final text = AbstractParser.parseInvertedIndex({'OpenAlex': 1});

      expect(text, startsWith('Error parsing abstract:'));
    });
  });

  group('AnalysisHelper', () {
    final publications = [
      _publication(
        title: 'B paper',
        year: 2024,
        citations: 20,
        journal: 'Journal B',
        authors: ['Ada', 'Grace'],
      ),
      _publication(
        title: 'A paper',
        year: 2025,
        citations: 20,
        journal: 'Journal A',
        authors: ['Ada'],
      ),
      _publication(
        title: 'C paper',
        year: 2025,
        citations: 5,
        journal: 'Unknown Source',
        authors: ['Unknown Author'],
      ),
    ];

    test('calculates citation totals and averages', () {
      expect(AnalysisHelper.getTotalCitations(publications), 45);
      expect(AnalysisHelper.getAverageCitations(publications), 15);
      expect(AnalysisHelper.getAverageCitations([]), 0);
    });

    test('ranks journals and ignores unknown journal labels', () {
      final journals = AnalysisHelper.getTopJournals(publications);

      expect(journals.keys, ['Journal A', 'Journal B']);
      expect(journals['Journal A'], 1);
    });

    test('ranks authors and ignores unknown authors', () {
      final authors = AnalysisHelper.getTopAuthors(publications);

      expect(authors['Ada'], 2);
      expect(authors['Grace'], 1);
      expect(authors.containsKey('Unknown Author'), isFalse);
    });

    test('sorts top cited papers by citations then title', () {
      final top = AnalysisHelper.getTopCitedPapers(publications, limit: 2);

      expect(top.map((pub) => pub.title), ['A paper', 'B paper']);
      expect(AnalysisHelper.getTopCitedPapers(publications, limit: 0), isEmpty);
    });

    test('counts publications by year and finds the most active year', () {
      expect(AnalysisHelper.getPublicationCountByYear(publications), {
        2024: 1,
        2025: 2,
      });
      expect(AnalysisHelper.getMostActivePublicationYear(publications), 2025);
      expect(AnalysisHelper.getMostActivePublicationYear([]), isNull);
    });

    test('uses the latest year when publication counts are tied', () {
      final tiedPublications = [
        _publication(
          title: 'Older year',
          year: 2023,
          citations: 1,
          journal: 'Journal A',
          authors: ['Ada'],
        ),
        _publication(
          title: 'Newer year',
          year: 2024,
          citations: 1,
          journal: 'Journal A',
          authors: ['Ada'],
        ),
      ];

      expect(
        AnalysisHelper.getMostActivePublicationYear(tiedPublications),
        2024,
      );
    });
  });
}

Publication _publication({
  required String title,
  required int year,
  required int citations,
  required String journal,
  required List<String> authors,
}) {
  return Publication(
    id: title,
    title: title,
    publicationYear: year,
    publicationDate: '$year-01-01',
    citedByCount: citations,
    journalName: journal,
    authors: authors
        .map((name) => Author(id: name, name: name))
        .toList(growable: false),
    doi: '',
    abstractText: '',
    topics: const [],
  );
}
