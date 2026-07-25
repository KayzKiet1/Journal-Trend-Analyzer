class DashboardSummary {
  const DashboardSummary({
    required this.userCount,
    required this.newUsers7d,
    required this.newUsers30d,
    required this.storageFileCount,
    required this.storageTotalBytes,
    required this.storageFolderCounts,
    required this.recentSystemHealthCount,
    required this.analyticsEvents7d,
    required this.activeUsers7d,
    required this.collectionCounts,
    required this.generatedAt,
  });

  final int userCount;
  final int newUsers7d;
  final int newUsers30d;
  final int storageFileCount;
  final int storageTotalBytes;
  final Map<String, int> storageFolderCounts;
  final int recentSystemHealthCount;
  final int analyticsEvents7d;
  final int activeUsers7d;
  final Map<String, int> collectionCounts;
  final DateTime? generatedAt;

  int get journalCount => collectionCounts['journals'] ?? 0;

  int get publicationCount => collectionCounts['publications'] ?? 0;

  int get appConfigCount => collectionCounts['appConfig'] ?? 0;

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    final rawCollectionCounts =
        map['collectionCounts'] as Map<dynamic, dynamic>? ?? const {};
    final rawStorageFolderCounts =
        map['storageFolderCounts'] as Map<dynamic, dynamic>? ?? const {};

    return DashboardSummary(
      userCount: _readInt(map['userCount']),
      newUsers7d: _readInt(map['newUsers7d']),
      newUsers30d: _readInt(map['newUsers30d']),
      storageFileCount: _readInt(map['storageFileCount']),
      storageTotalBytes: _readInt(map['storageTotalBytes']),
      storageFolderCounts: rawStorageFolderCounts.map(
        (key, value) => MapEntry(key.toString(), _readInt(value)),
      ),
      recentSystemHealthCount: _readInt(map['recentSystemHealthCount']),
      analyticsEvents7d: _readInt(map['analyticsEvents7d']),
      activeUsers7d: _readInt(map['activeUsers7d']),
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
