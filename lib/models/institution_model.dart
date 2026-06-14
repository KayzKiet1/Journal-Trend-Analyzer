/// Lớp đại diện cho tổ chức/trường học (Institution entity trong OpenAlex)
class Institution {
  final String id;
  final String name;
  final String? type;
  final String? countryCode;
  final int worksCount;
  final int citedByCount;

  Institution({
    required this.id,
    required this.name,
    this.type,
    this.countryCode,
    this.worksCount = 0,
    this.citedByCount = 0,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'] ?? '',
      name: json['display_name'] ?? 'Unknown Institution',
      type: json['type'],
      countryCode: json['country_code'],
      worksCount: json['works_count'] ?? 0,
      citedByCount: json['cited_by_count'] ?? 0,
    );
  }
}
