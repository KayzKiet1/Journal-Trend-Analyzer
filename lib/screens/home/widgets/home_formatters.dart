String compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

MapEntry<String, int>? firstEntry(Map<String, int> map) {
  if (map.isEmpty) return null;
  return map.entries.first;
}
