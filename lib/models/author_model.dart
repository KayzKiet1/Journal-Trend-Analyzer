class Author {
  const Author({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory Author.fromOpenAlexJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const Author(id: '', name: 'Unknown Author');
    }

    return Author(
      id: _asString(json['id']),
      name: _asString(json['display_name'], fallback: 'Unknown Author'),
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
