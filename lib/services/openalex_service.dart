import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/publication_model.dart';
import '../models/trend_data_model.dart';
import '../utils/api_constants.dart';

/// Dịch vụ kết nối và lấy dữ liệu từ OpenAlex API
class OpenAlexService {
  /// Tìm kiếm các bài báo theo từ khóa (topic)
  /// Sắp xếp theo số lượng trích dẫn giảm dần để lấy các bài báo có ảnh hưởng nhất
  Future<List<Publication>> searchWorks(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'search': query,
        'sort': 'cited_by_count:desc',
        'mailto': ApiConstants.contactEmail,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => Publication.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi khi tải dữ liệu từ OpenAlex: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API: $e');
    }
  }

  /// Lấy dữ liệu xu hướng số lượng bài báo theo năm của một chủ đề
  Future<List<TrendData>> getYearlyTrend(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'search': query,
        'group_by': 'publication_year',
        'mailto': ApiConstants.contactEmail,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List groups = data['group_by'] ?? [];
        
        // Chuyển đổi và sắp xếp theo năm tăng dần
        List<TrendData> trends = groups.map((json) => TrendData.fromJson(json)).toList();
        trends.sort((a, b) => a.year.compareTo(b.year));
        
        // Chỉ lấy các năm gần đây (ví dụ 10 năm) để biểu đồ không bị quá dày
        if (trends.length > 10) {
          trends = trends.sublist(trends.length - 10);
        }
        
        return trends;
      } else {
        throw Exception('Lỗi khi tải dữ liệu xu hướng: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API: $e');
    }
  }
}
