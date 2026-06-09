/// Lớp hỗ trợ phân tích và chuyển đổi tóm tắt bài báo từ dạng inverted index sang văn bản thuần
class AbstractParser {
  /// Chuyển đổi abstract_inverted_index của OpenAlex thành chuỗi văn bản
  /// OpenAlex trả về một map trong đó key là từ, value là danh sách các vị trí của từ đó trong văn bản
  static String parseInvertedIndex(Map<String, dynamic>? invertedIndex) {
    if (invertedIndex == null || invertedIndex.isEmpty) {
      return "No abstract available.";
    }

    try {
      // Tìm độ dài tối đa của tóm tắt dựa trên vị trí lớn nhất
      int maxIndex = 0;
      invertedIndex.forEach((word, positions) {
        for (var pos in positions) {
          if (pos is int && pos > maxIndex) {
            maxIndex = pos;
          }
        }
      });

      // Khởi tạo một danh sách các từ với kích thước phù hợp
      List<String?> words = List.filled(maxIndex + 1, null);

      // Đặt các từ vào đúng vị trí của chúng
      invertedIndex.forEach((word, positions) {
        for (var pos in positions) {
          if (pos is int) {
            words[pos] = word;
          }
        }
      });

      // Nối các từ lại thành một đoạn văn, bỏ qua các vị trí null nếu có
      return words.where((w) => w != null).join(' ');
    } catch (e) {
      return "Error parsing abstract: $e";
    }
  }
}
