class ResearchTopic {
  final String id;
  final String name;
  final String? description;
  final int worksCount;

  const ResearchTopic({
    required this.id,
    required this.name,
    this.description,
    this.worksCount = 0,
  });

  factory ResearchTopic.fromJson(Map<String, dynamic> json) {
    return ResearchTopic(
      id: json['id']?.toString() ?? '',
      name: json['display_name']?.toString() ?? 'Unknown topic',
      description: json['description']?.toString() ?? json['hint']?.toString(),
      worksCount: (json['works_count'] as num?)?.toInt() ?? 0,
    );
  }
}
