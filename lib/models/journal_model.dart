class Journal {
  const Journal({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory Journal.fromOpenAlexJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const Journal(id: '', name: 'Unknown Journal');
    }

    return Journal(
      id: _asString(json['id']),
      name: _asString(json['display_name'], fallback: 'Unknown Journal'),
    );
  }

  static String _asString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;
    return value.toString();
  }
}
