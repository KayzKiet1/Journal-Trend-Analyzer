/// Lớp đại diện cho tác giả của bài báo
class Author {
  final String id;
  final String name;

  Author({required this.id, required this.name});

  /// Chuyển đổi từ dữ liệu JSON của OpenAlex sang đối tượng Author
  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['author']?['id'] ?? '',
      name: json['author']?['display_name'] ?? 'Unknown Author',
    );
  }
}
