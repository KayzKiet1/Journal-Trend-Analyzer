import 'author_model.dart';
import '../utils/abstract_parser.dart';

/// Lớp đại diện cho một bài báo nghiên cứu (Publication/Work) từ OpenAlex
class Publication {
  final String id;
  final String title;
  final int publicationYear;
  final String publicationDate;
  final int citedByCount;
  final String journalId;
  final String journalName;
  final List<Author> authors;
  final String doi;
  final String abstractText;
  final List<String> topics;

  Publication({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.publicationDate,
    required this.citedByCount,
    this.journalId = '',
    required this.journalName,
    required this.authors,
    required this.doi,
    required this.abstractText,
    required this.topics,
  });

  /// Chuyển đổi từ dữ liệu JSON của OpenAlex sang đối tượng Publication
  factory Publication.fromJson(Map<String, dynamic> json) {
    // Lấy danh sách tác giả
    var authorships = json['authorships'] as List? ?? [];
    List<Author> authorsList = authorships
        .map((a) => Author.fromJson(a as Map<String, dynamic>))
        .toList();

    // Lấy tên tạp chí
    final source = json['primary_location']?['source'];
    String journalId = source?['id'] ?? '';
    String journal = source?['display_name'] ?? 'Unknown Source';

    // Xử lý abstract từ inverted index
    String parsedAbstract = AbstractParser.parseInvertedIndex(
      json['abstract_inverted_index'] as Map<String, dynamic>?,
    );

    // Lấy danh sách topics hoặc concepts làm fallback
    var topicsJson = json['topics'] as List? ?? [];
    List<String> topicsList = topicsJson
        .map((t) => t['display_name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    if (topicsList.isEmpty) {
      var conceptsJson = json['concepts'] as List? ?? [];
      topicsList = conceptsJson
          .map((c) => c['display_name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    }

    return Publication(
      id: json['id'] ?? '',
      title: json['display_name'] ?? 'Untitled',
      publicationYear: json['publication_year'] ?? 0,
      publicationDate: json['publication_date'] ?? '',
      citedByCount: json['cited_by_count'] ?? 0,
      journalId: journalId,
      journalName: journal,
      authors: authorsList,
      doi: json['doi'] ?? '',
      abstractText: parsedAbstract,
      topics: topicsList,
    );
  }

  factory Publication.fromStoredJson(Map<String, dynamic> json) {
    return Publication(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      publicationYear: json['publication_year'] as int? ?? 0,
      publicationDate: json['publication_date']?.toString() ?? '',
      citedByCount: json['cited_by_count'] as int? ?? 0,
      journalId: json['journal_id']?.toString() ?? '',
      journalName: json['journal_name']?.toString() ?? 'Unknown Source',
      authors:
          (json['authors'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(Author.fromStoredJson)
              .toList() ??
          [],
      doi: json['doi']?.toString() ?? '',
      abstractText: json['abstract_text']?.toString() ?? '',
      topics:
          (json['topics'] as List?)
              ?.map((topic) => topic.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toStoredJson() {
    return {
      'id': id,
      'title': title,
      'publication_year': publicationYear,
      'publication_date': publicationDate,
      'cited_by_count': citedByCount,
      'journal_id': journalId,
      'journal_name': journalName,
      'authors': authors.map((author) => author.toStoredJson()).toList(),
      'doi': doi,
      'abstract_text': abstractText,
      'topics': topics,
    };
  }

  /// Trả về chuỗi danh sách tên các tác giả cách nhau bởi dấu phẩy
  String get authorsString => authors.map((a) => a.name).join(', ');
}
