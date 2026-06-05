import 'package:journal_trend_analyzer/models/author_model.dart';
import 'package:journal_trend_analyzer/utils/abstract_parser.dart';

class Publication {
  const Publication({
    required this.id,
    required this.title,
    this.publicationYear,
    this.publicationDate,
    this.citedByCount = 0,
    this.journalName = '',
    this.authors = const [],
    this.doi = '',
    this.abstractText = '',
  });

  final String id;
  final String title;
  final int? publicationYear;
  final String? publicationDate;
  final int citedByCount;
  final String journalName;
  final List<Author> authors;
  final String doi;
  final String abstractText;

  factory Publication.fromOpenAlexJson(Map<String, dynamic> json) {
    final primaryLocation = json['primary_location'];
    final source = primaryLocation is Map<String, dynamic>
        ? primaryLocation['source']
        : null;

    final authorships = json['authorships'];
    final authors = <Author>[];
    if (authorships is List) {
      for (final authorship in authorships) {
        if (authorship is Map<String, dynamic>) {
          final authorJson = authorship['author'];
          authors.add(
            Author.fromOpenAlexJson(
              authorJson is Map<String, dynamic> ? authorJson : null,
            ),
          );
        }
      }
    }

    final abstractIndex = json['abstract_inverted_index'];
    final abstractText = abstractIndex is Map<String, dynamic>
        ? parseAbstractInvertedIndex(abstractIndex)
        : '';

    return Publication(
      id: _asString(json['id']),
      title: _asString(json['display_name'], fallback: 'Untitled'),
      publicationYear: _asInt(json['publication_year']),
      publicationDate: _asNullableString(json['publication_date']),
      citedByCount: _asInt(json['cited_by_count']) ?? 0,
      journalName: source is Map<String, dynamic>
          ? _asString(source['display_name'])
          : '',
      authors: authors,
      doi: _normalizeDoi(json['doi']),
      abstractText: abstractText,
    );
  }

  static String _asString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;
    return value.toString();
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String _normalizeDoi(dynamic value) {
    if (value == null) return '';

    final doi = value.toString().trim();
    if (doi.isEmpty) return '';

    const prefix = 'https://doi.org/';
    if (doi.startsWith(prefix)) {
      return doi.substring(prefix.length);
    }

    return doi;
  }
}
