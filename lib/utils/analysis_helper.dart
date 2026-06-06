import '../models/publication_model.dart';

/// Lớp hỗ trợ tính toán các số liệu thống kê từ danh sách bài báo
class AnalysisHelper {
  /// Tính tổng số lượng trích dẫn của tất cả các bài báo trong danh sách
  static int getTotalCitations(List<Publication> publications) {
    return publications.fold(0, (sum, pub) => sum + pub.citedByCount);
  }

  /// Tính trung bình số lượng trích dẫn mỗi bài báo
  static double getAverageCitations(List<Publication> publications) {
    if (publications.isEmpty) return 0.0;
    return getTotalCitations(publications) / publications.length;
  }

  /// Tìm danh sách các tạp chí phổ biến nhất (xuất hiện nhiều nhất)
  static Map<String, int> getTopJournals(List<Publication> publications) {
    Map<String, int> journalCounts = {};
    for (var pub in publications) {
      journalCounts[pub.journalName] = (journalCounts[pub.journalName] ?? 0) + 1;
    }
    
    // Sắp xếp theo số lượng bài báo giảm dần
    var sortedEntries = journalCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(5));
  }

  /// Tìm danh sách các tác giả đóng góp nhiều nhất trong tập dữ liệu hiện tại
  static Map<String, int> getTopAuthors(List<Publication> publications) {
    Map<String, int> authorCounts = {};
    for (var pub in publications) {
      for (var author in pub.authors) {
        authorCounts[author.name] = (authorCounts[author.name] ?? 0) + 1;
      }
    }
    
    var sortedEntries = authorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(5));
  }
}
