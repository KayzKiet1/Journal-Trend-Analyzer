import '../models/publication_model.dart';

/// Lớp hỗ trợ tính toán các số liệu thống kê từ danh sách bài báo
class AnalysisHelper {
  AnalysisHelper._();

  static const String _unknownAuthorLabel = 'unknown author';
  static const Set<String> _unknownJournalLabels = {
    'unknown journal',
    'unknown source',
  };

  /// Tính tổng số lượng trích dẫn của tất cả các bài báo trong danh sách
  static int getTotalCitations(List<Publication> publications) {
    return publications.fold(0, (sum, pub) => sum + pub.citedByCount);
  }

  /// Tính trung bình số lượng trích dẫn mỗi bài báo
  static double getAverageCitations(List<Publication> publications) {
    if (publications.isEmpty) return 0.0;
    return getTotalCitations(publications) / publications.length;
  }

  /// Tìm Top 5 tạp chí theo số lượng bài báo (giảm dần, hòa thì theo tên)
  static Map<String, int> getTopJournals(List<Publication> publications) {
    final journalCounts = <String, int>{};

    for (final pub in publications) {
      final journalName = _normalizeJournalName(pub.journalName);
      if (!_isUsableJournalName(journalName)) continue;
      journalCounts[journalName] = (journalCounts[journalName] ?? 0) + 1;
    }

    return _takeTopRanked(journalCounts);
  }

  /// Tìm Top 5 tác giả theo số lượng bài báo (giảm dần, hòa thì theo tên)
  static Map<String, int> getTopAuthors(List<Publication> publications) {
    final authorCounts = <String, int>{};

    for (final pub in publications) {
      for (final author in pub.authors) {
        final authorName = _normalizeAuthorName(author.name);
        if (!_isUsableAuthorName(authorName)) continue;
        authorCounts[authorName] = (authorCounts[authorName] ?? 0) + 1;
      }
    }

    return _takeTopRanked(authorCounts);
  }

  /// Lấy các bài báo có lượng trích dẫn cao nhất
  static List<Publication> getTopCitedPapers(
    List<Publication> publications, {
    int limit = 5,
  }) {
    if (publications.isEmpty || limit <= 0) return [];

    final sorted = List<Publication>.from(publications)
      ..sort((a, b) {
        final byCitations = b.citedByCount.compareTo(a.citedByCount);
        if (byCitations != 0) return byCitations;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

    return sorted.take(limit).toList();
  }

  /// Đếm số lượng bài báo theo từng năm xuất bản
  static Map<int, int> getPublicationCountByYear(List<Publication> publications) {
    final yearCounts = <int, int>{};

    for (final pub in publications) {
      if (!_isValidYear(pub.publicationYear)) continue;
      yearCounts[pub.publicationYear] =
          (yearCounts[pub.publicationYear] ?? 0) + 1;
    }

    final sortedYears = yearCounts.keys.toList()..sort();
    return {for (final year in sortedYears) year: yearCounts[year]!};
  }

  /// Tìm năm xuất bản có nhiều bài báo nhất
  static int? getMostActivePublicationYear(List<Publication> publications) {
    final yearCounts = getPublicationCountByYear(publications);
    if (yearCounts.isEmpty) return null;

    int? mostActiveYear;
    var highestCount = 0;

    for (final entry in yearCounts.entries) {
      if (entry.value > highestCount) {
        highestCount = entry.value;
        mostActiveYear = entry.key;
      } else if (entry.value == highestCount && mostActiveYear != null) {
        if (entry.key > mostActiveYear) {
          mostActiveYear = entry.key;
        }
      }
    }

    return mostActiveYear;
  }

  static Map<String, int> _takeTopRanked(Map<String, int> counts) {
    final sortedEntries = counts.entries.toList()
      ..sort(_compareByCountThenName);

    return Map.fromEntries(sortedEntries.take(5));
  }

  static int _compareByCountThenName(
    MapEntry<String, int> a,
    MapEntry<String, int> b,
  ) {
    final byCount = b.value.compareTo(a.value);
    if (byCount != 0) return byCount;
    return a.key.toLowerCase().compareTo(b.key.toLowerCase());
  }

  static String _normalizeAuthorName(String name) => name.trim();

  static String _normalizeJournalName(String name) => name.trim();

  static bool _isUsableAuthorName(String name) {
    if (name.isEmpty) return false;
    return name.toLowerCase() != _unknownAuthorLabel;
  }

  static bool _isUsableJournalName(String name) {
    if (name.isEmpty) return false;
    return !_unknownJournalLabels.contains(name.toLowerCase());
  }

  static bool _isValidYear(int year) => year > 0;
}
