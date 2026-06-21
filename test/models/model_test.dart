import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/models/author_model.dart';
import 'package:journal_trend_analyzer/models/journal_model.dart';
import 'package:journal_trend_analyzer/models/publication_model.dart';
import 'package:journal_trend_analyzer/models/trend_data_model.dart';
import 'package:journal_trend_analyzer/models/institution_model.dart';

void main() {
  group('Model JSON Mapping Tests', () {
    test('Author.fromJson', () {
      final json = {
        'author': {'id': 'A1', 'display_name': 'Author One'},
        'last_known_institution': {'display_name': 'Inst One'},
        'works_count': 10,
        'cited_by_count': 100
      };
      final author = Author.fromJson(json);
      expect(author.id, 'A1');
      expect(author.name, 'Author One');
      expect(author.lastKnownInstitution, 'Inst One');
      expect(author.worksCount, 10);
      expect(author.citedByCount, 100);
    });

    test('Author.fromJson with missing data', () {
      final json = {'author': null};
      final author = Author.fromJson(json);
      expect(author.id, '');
      expect(author.name, 'Unknown Author');
      expect(author.lastKnownInstitution, isNull);
    });

    test('Journal.fromJson', () {
      final json = {
        'id': 'J1',
        'display_name': 'Journal One',
        'host_organization_name': 'Org One',
        'works_count': 100,
        'cited_by_count': 500,
        'homepage_url': 'http://j1.com',
        'issn': ['1234-5678'],
        'counts_by_year': [
          {'year': 2023, 'works_count': 10, 'cited_by_count': 50}
        ]
      };
      final journal = Journal.fromJson(json);
      expect(journal.id, 'J1');
      expect(journal.name, 'Journal One');
      expect(journal.issns, contains('1234-5678'));
      expect(journal.countsByYear.first.year, 2023);
    });

    test('Publication.fromJson', () {
      final json = {
        'id': 'P1',
        'display_name': 'Pub One',
        'publication_year': 2023,
        'publication_date': '2023-01-01',
        'cited_by_count': 10,
        'primary_location': {'source': {'display_name': 'Source One'}},
        'authorships': [
          {
            'author': {'id': 'A1', 'display_name': 'Author One'}
          }
        ],
        'doi': 'http://doi.org/1',
        'abstract_inverted_index': {'The': [0]},
        'topics': [{'display_name': 'Topic One'}]
      };
      final pub = Publication.fromJson(json);
      expect(pub.id, 'P1');
      expect(pub.title, 'Pub One');
      expect(pub.topics, ['Topic One']);
      expect(pub.authorsString, 'Author One');
    });

    test('TrendData.fromJson', () {
      final json = {'key': '2023', 'count': 50};
      final trend = TrendData.fromJson(json);
      expect(trend.year, 2023);
      expect(trend.count, 50);
    });

    test('Institution.fromJson', () {
      final json = {
        'id': 'I1',
        'display_name': 'Inst One',
        'country_code': 'VN',
        'works_count': 20,
        'cited_by_count': 100,
        'image_url': 'http://img.com'
      };
      final inst = Institution.fromJson(json);
      expect(inst.id, 'I1');
      expect(inst.name, 'Inst One');
      expect(inst.countryCode, 'VN');
    });
  });
}
