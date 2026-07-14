/// Lớp đại diện cho tác giả (Author entity trong OpenAlex)
class Author {
  final String id;
  final String name;
  final int worksCount;
  final int citedByCount;
  final String? lastKnownInstitution;

  Author({
    required this.id,
    required this.name,
    this.worksCount = 0,
    this.citedByCount = 0,
    this.lastKnownInstitution,
  });

  /// Chuyển đổi từ dữ liệu JSON của OpenAlex sang đối tượng Author
  factory Author.fromJson(Map<String, dynamic> json) {
    // Xử lý cả trường hợp author nằm trong authorship hoặc là entity độc lập
    final dynamic authorField = json['author'];
    final Map<String, dynamic> authorData =
        (authorField is Map<String, dynamic>) ? authorField : json;

    return Author(
      id: authorData['id'] ?? '',
      name: authorData['display_name'] ?? 'Unknown Author',
      worksCount: json['works_count'] ?? 0,
      citedByCount: json['cited_by_count'] ?? 0,
      lastKnownInstitution: json['last_known_institution']?['display_name'],
    );
  }
}
