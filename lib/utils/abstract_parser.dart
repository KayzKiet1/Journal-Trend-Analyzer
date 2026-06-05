/// Converts OpenAlex [abstract_inverted_index] JSON into readable plain text.
String parseAbstractInvertedIndex(Map<String, dynamic>? invertedIndex) {
  if (invertedIndex == null || invertedIndex.isEmpty) {
    return '';
  }

  var maxPosition = -1;
  for (final positions in invertedIndex.values) {
    if (positions is! List) continue;
    for (final position in positions) {
      if (position is int && position > maxPosition) {
        maxPosition = position;
      }
    }
  }

  if (maxPosition < 0) {
    return '';
  }

  final words = List<String?>.filled(maxPosition + 1, null);

  invertedIndex.forEach((word, positions) {
    if (positions is! List) return;
    for (final position in positions) {
      if (position is int && position >= 0 && position < words.length) {
        words[position] = word;
      }
    }
  });

  return words.whereType<String>().join(' ');
}
