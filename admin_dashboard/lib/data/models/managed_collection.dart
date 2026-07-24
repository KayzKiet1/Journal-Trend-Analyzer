class ManagedCollection {
  const ManagedCollection({required this.name, required this.count});

  final String name;
  final int count;

  factory ManagedCollection.fromMap(Map<String, dynamic> map) {
    return ManagedCollection(
      name: map['name']?.toString() ?? '',
      count: _readInt(map['count']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
