import 'author_model.dart';
import '../utils/abstract_parser.dart';

/// Lớp đại diện cho một bài báo nghiên cứu (Publication/Work) từ OpenAlex
class Publication {
  final String id;
  final String title;
  final int publicationYear;
  final String publicationDate;
  final int citedByCount;
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
    String journal = json['primary_location']?['source']?['display_name'] ?? 'Unknown Source';

    // Xử lý abstract từ inverted index
    String parsedAbstract = AbstractParser.parseInvertedIndex(
      json['abstract_inverted_index'] as Map<String, dynamic>?
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
      journalName: journal,
      authors: authorsList,
      doi: json['doi'] ?? '',
      abstractText: parsedAbstract,
      topics: topicsList,
    );
  }

  /// Trả về chuỗi danh sách tên các tác giả cách nhau bởi dấu phẩy
  String get authorsString => authors.map((a) => a.name).join(', ');
}
