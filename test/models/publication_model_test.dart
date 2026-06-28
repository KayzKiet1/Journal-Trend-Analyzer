import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/models/author_model.dart';
import 'package:journal_trend_analyzer/models/publication_model.dart';
import 'package:journal_trend_analyzer/models/trend_data_model.dart';

void main() {
  group('Author', () {
    test('parses nested OpenAlex authorship data', () {
      final author = Author.fromJson({
        'author': {'id': 'https://openalex.org/A1', 'display_name': 'Ada'},
        'works_count': 12,
        'cited_by_count': 34,
        'last_known_institution': {'display_name': 'Open University'},
      });

      expect(author.id, 'https://openalex.org/A1');
      expect(author.name, 'Ada');
      expect(author.worksCount, 12);
      expect(author.citedByCount, 34);
      expect(author.lastKnownInstitution, 'Open University');
    });

    test('falls back when author data is missing', () {
      final author = Author.fromJson({});

      expect(author.id, isEmpty);
      expect(author.name, 'Unknown Author');
      expect(author.worksCount, 0);
      expect(author.citedByCount, 0);
    });
  });

  group('Publication', () {
    test('parses OpenAlex work data with topics and abstract', () {
      final publication = Publication.fromJson({
        'id': 'https://openalex.org/W1',
        'display_name': 'Trend Analysis for Journals',
        'publication_year': 2026,
        'publication_date': '2026-06-28',
        'cited_by_count': 99,
        'doi': 'https://doi.org/10.1000/test',
        'primary_location': {
          'source': {'display_name': 'Journal Analytics'},
        },
        'authorships': [
          {
            'author': {'id': 'A1', 'display_name': 'Ada'},
          },
          {
            'author': {'id': 'A2', 'display_name': 'Grace'},
          },
        ],
        'abstract_inverted_index': {
          'Journal': [0],
          'trend': [1],
          'analysis': [2],
        },
        'topics': [
          {'display_name': 'Bibliometrics'},
          {'display_name': 'Scholarly Communication'},
        ],
      });

      expect(publication.id, 'https://openalex.org/W1');
      expect(publication.title, 'Trend Analysis for Journals');
      expect(publication.publicationYear, 2026);
      expect(publication.citedByCount, 99);
      expect(publication.journalName, 'Journal Analytics');
      expect(publication.authorsString, 'Ada, Grace');
      expect(publication.abstractText, 'Journal trend analysis');
      expect(publication.topics, contains('Bibliometrics'));
    });

    test('uses concepts when topics are not available', () {
      final publication = Publication.fromJson({
        'concepts': [
          {'display_name': 'Open Science'},
          {'display_name': ''},
        ],
      });

      expect(publication.title, 'Untitled');
      expect(publication.journalName, 'Unknown Source');
      expect(publication.abstractText, 'No abstract available.');
      expect(publication.topics, ['Open Science']);
    });
  });

  group('TrendData', () {
    test('parses grouped OpenAlex data', () {
      final trend = TrendData.fromJson({'key': '2025', 'count': 15});

      expect(trend.year, 2025);
      expect(trend.count, 15);
    });

    test('uses zero for invalid year keys', () {
      final trend = TrendData.fromJson({'key': 'not-a-year'});

      expect(trend.year, 0);
      expect(trend.count, 0);
    });
  });
}
