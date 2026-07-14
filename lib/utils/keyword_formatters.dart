String keywordId(String idOrUrl) {
  final parsed = Uri.tryParse(idOrUrl);
  if (parsed != null && parsed.pathSegments.isNotEmpty) {
    return parsed.pathSegments.last;
  }
  return idOrUrl.split('/').last;
}
