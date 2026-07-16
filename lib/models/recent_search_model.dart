import 'dart:convert';

class RecentSearch {
  final String label;
  final List<String> topicIds;
  final List<String> topicNames;

  const RecentSearch({
    required this.label,
    this.topicIds = const [],
    this.topicNames = const [],
  });

  factory RecentSearch.fromStored(String value) {
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return RecentSearch(
        label: decoded['label']?.toString() ?? '',
        topicIds:
            (decoded['topic_ids'] as List?)
                ?.map((id) => id.toString())
                .toList() ??
            [],
        topicNames:
            (decoded['topic_names'] as List?)
                ?.map((name) => name.toString())
                .toList() ??
            [],
      );
    } catch (_) {
      return RecentSearch(label: value);
    }
  }

  String toStored() {
    if (topicIds.isEmpty) return label;
    return jsonEncode({
      'label': label,
      'topic_ids': topicIds,
      'topic_names': topicNames,
    });
  }
}
