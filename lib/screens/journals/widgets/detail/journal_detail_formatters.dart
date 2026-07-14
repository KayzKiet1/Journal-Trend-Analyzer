String compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

String yesNo(bool? value) {
  if (value == null) return 'Unknown';
  return value ? 'Yes' : 'No';
}
