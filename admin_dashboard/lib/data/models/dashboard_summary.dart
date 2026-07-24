class DashboardSummary {
  const DashboardSummary({
    required this.userCount,
    required this.storageFileCount,
    required this.collectionCounts,
    required this.generatedAt,
  });

  final int userCount;
  final int storageFileCount;
  final Map<String, int> collectionCounts;
  final DateTime? generatedAt;

  int get journalCount => collectionCounts['journals'] ?? 0;

  int get publicationCount => collectionCounts['publications'] ?? 0;

  int get appConfigCount => collectionCounts['appConfig'] ?? 0;

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    final rawCollectionCounts =
        map['collectionCounts'] as Map<dynamic, dynamic>? ?? const {};

    return DashboardSummary(
      userCount: _readInt(map['userCount']),
      storageFileCount: _readInt(map['storageFileCount']),
      collectionCounts: rawCollectionCounts.map(
        (key, value) => MapEntry(key.toString(), _readInt(value)),
      ),
      generatedAt: DateTime.tryParse(map['generatedAt']?.toString() ?? ''),
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
