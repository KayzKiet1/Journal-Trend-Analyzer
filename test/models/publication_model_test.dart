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

    test('stores and restores author snapshots', () {
      final author = Author(
        id: 'A123',
        name: 'Katherine Johnson',
        worksCount: 7,
        citedByCount: 42,
        lastKnownInstitution: 'NASA',
      );

      final restored = Author.fromStoredJson(author.toStoredJson());

      expect(restored.id, author.id);
      expect(restored.name, author.name);
      expect(restored.worksCount, author.worksCount);
      expect(restored.citedByCount, author.citedByCount);
      expect(restored.lastKnownInstitution, author.lastKnownInstitution);
    });

    test('restores author defaults from sparse stored data', () {
      final author = Author.fromStoredJson({});

      expect(author.id, isEmpty);
      expect(author.name, 'Unknown Author');
      expect(author.worksCount, 0);
      expect(author.citedByCount, 0);
      expect(author.lastKnownInstitution, isNull);
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
          'source': {
            'id': 'https://openalex.org/S1',
            'display_name': 'Journal Analytics',
          },
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
        'keywords': [
          {'display_name': 'Journal trends'},
          {'display_name': 'Research analytics'},
        ],
      });

      expect(publication.id, 'https://openalex.org/W1');
      expect(publication.title, 'Trend Analysis for Journals');
      expect(publication.publicationYear, 2026);
      expect(publication.citedByCount, 99);
      expect(publication.journalId, 'https://openalex.org/S1');
      expect(publication.journalName, 'Journal Analytics');
      expect(publication.authorsString, 'Ada, Grace');
      expect(publication.abstractText, 'Journal trend analysis');
      expect(publication.topics, contains('Bibliometrics'));
      expect(publication.keywords, contains('Journal trends'));
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

    test('stores and restores publication snapshots', () {
      final publication = Publication(
        id: 'W123',
        title: 'Reliable Journal Trend Tests',
        publicationYear: 2025,
        publicationDate: '2025-12-31',
        citedByCount: 18,
        journalId: 'S123',
        journalName: 'Journal of Test Coverage',
        authors: [
          Author(id: 'A1', name: 'Ada Lovelace', worksCount: 2),
          Author(id: 'A2', name: 'Grace Hopper', citedByCount: 9),
        ],
        doi: '10.1000/coverage',
        abstractText: 'Coverage should stay comfortably above the gate.',
        topics: ['Software quality', 'Testing'],
        keywords: ['coverage', 'sonar'],
      );

      final restored = Publication.fromStoredJson(publication.toStoredJson());

      expect(restored.id, publication.id);
      expect(restored.title, publication.title);
      expect(restored.publicationYear, publication.publicationYear);
      expect(restored.publicationDate, publication.publicationDate);
      expect(restored.citedByCount, publication.citedByCount);
      expect(restored.journalId, publication.journalId);
      expect(restored.journalName, publication.journalName);
      expect(restored.authorsString, 'Ada Lovelace, Grace Hopper');
      expect(restored.doi, publication.doi);
      expect(restored.abstractText, publication.abstractText);
      expect(restored.topics, publication.topics);
      expect(restored.keywords, publication.keywords);
    });

    test('restores publication defaults from sparse stored data', () {
      final publication = Publication.fromStoredJson({
        'topics': ['Machine learning', 2026],
        'keywords': ['ai', null],
      });

      expect(publication.id, isEmpty);
      expect(publication.title, 'Untitled');
      expect(publication.publicationYear, 0);
      expect(publication.publicationDate, isEmpty);
      expect(publication.citedByCount, 0);
      expect(publication.journalId, isEmpty);
      expect(publication.journalName, 'Unknown Source');
      expect(publication.authors, isEmpty);
      expect(publication.doi, isEmpty);
      expect(publication.abstractText, isEmpty);
      expect(publication.topics, ['Machine learning', '2026']);
      expect(publication.keywords, ['ai', 'null']);
    });

    test('restores empty topic, keyword and author lists from missing data', () {
      final publication = Publication.fromStoredJson({
        'id': 'W-empty-lists',
        'journal_name': 'Journal of Sparse Records',
      });

      expect(publication.id, 'W-empty-lists');
      expect(publication.authors, isEmpty);
      expect(publication.topics, isEmpty);
      expect(publication.keywords, isEmpty);
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
