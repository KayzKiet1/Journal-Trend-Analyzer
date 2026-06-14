/// Lớp đại diện cho nguồn xuất bản (Source/Journal entity trong OpenAlex)
class Journal {
  final String id;
  final String name;
  final String? type;
  final String? publisher;
  final int worksCount;
  final int citedByCount;

  Journal({
    required this.id, 
    required this.name,
    this.type,
    this.publisher,
    this.worksCount = 0,
    this.citedByCount = 0,
  });

  /// Chuyển đổi từ dữ liệu JSON của OpenAlex sang đối tượng Journal
  factory Journal.fromJson(Map<String, dynamic> json) {
    // Xử lý cả trường hợp source nằm trong location hoặc là entity độc lập
    final Map<String, dynamic> sourceData = json.containsKey('source') ? json['source'] : json;

    return Journal(
      id: sourceData['id'] ?? '',
      name: sourceData['display_name'] ?? 'Unknown Source',
      type: sourceData['type'],
      publisher: sourceData['publisher'] ?? json['host_organization_name'],
      worksCount: json['works_count'] ?? 0,
      citedByCount: json['cited_by_count'] ?? 0,
    );
  }
}
