/// Lớp đại diện cho tạp chí xuất bản bài báo
class Journal {
  final String id;
  final String name;

  Journal({required this.id, required this.name});

  /// Chuyển đổi từ dữ liệu JSON của OpenAlex sang đối tượng Journal
  factory Journal.fromJson(Map<String, dynamic> json) {
    // OpenAlex cấu trúc source bên trong primary_location
    final source = json['primary_location']?['source'];
    return Journal(
      id: source?['id'] ?? '',
      name: source?['display_name'] ?? 'Unknown Journal',
    );
  }
}
