/// Lớp đại diện cho dữ liệu xu hướng theo năm để hiển thị trên biểu đồ
class TrendData {
  final int year;
  final int count;

  TrendData({required this.year, required this.count});

  /// Chuyển đổi từ dữ liệu group_by của OpenAlex sang đối tượng TrendData
  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      year: int.tryParse(json['key'] ?? '0') ?? 0,
      count: json['count'] ?? 0,
    );
  }
}
