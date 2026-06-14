import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/publication_model.dart';
import '../models/trend_data_model.dart';
import '../models/author_model.dart';
import '../models/journal_model.dart';
import '../models/institution_model.dart';
import '../utils/api_constants.dart';

/// Dịch vụ kết nối và lấy dữ liệu từ OpenAlex API
class OpenAlexService {
  /// Tìm kiếm các bài báo theo từ khóa (topic) có hỗ trợ phân trang
  Future<Map<String, dynamic>> searchWorks(String query, {int page = 1, int perPage = 10}) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'search': query,
        'sort': 'cited_by_count:desc',
        'page': page.toString(),
        'per_page': perPage.toString(),
        'mailto': ApiConstants.contactEmail,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final int totalCount = data['meta']?['count'] ?? 0;
        
        return {
          'results': results.map((json) => Publication.fromJson(json)).toList(),
          'total_count': totalCount,
        };
      } else {
        throw Exception('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Tìm kiếm tác giả (Authors) có hỗ trợ phân trang
  Future<Map<String, dynamic>> searchAuthors(String query, {int page = 1, int perPage = 10}) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/authors').replace(
      queryParameters: {
        'search': query,
        'sort': 'works_count:desc',
        'page': page.toString(),
        'per_page': perPage.toString(),
        'mailto': ApiConstants.contactEmail,
      },
    );
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final int totalCount = data['meta']?['count'] ?? 0;
        
        return {
          'results': results.map((json) => Author.fromJson(json)).toList(),
          'total_count': totalCount,
        };
      } else {
        throw Exception('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Tìm kiếm nguồn xuất bản (Sources/Journals)
  Future<List<Journal>> searchSources(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/sources').replace(
      queryParameters: {
        'search': query,
        'sort': 'works_count:desc',
        'mailto': ApiConstants.contactEmail,
      },
    );
    return _fetchList(url, (json) => Journal.fromJson(json));
  }

  /// Tìm kiếm tổ chức/trường học (Institutions)
  Future<List<Institution>> searchInstitutions(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/institutions').replace(
      queryParameters: {
        'search': query,
        'sort': 'works_count:desc',
        'mailto': ApiConstants.contactEmail,
      },
    );
    return _fetchList(url, (json) => Institution.fromJson(json));
  }

  /// Tìm kiếm bài báo theo ID tác giả có hỗ trợ phân trang
  Future<Map<String, dynamic>> getWorksByAuthor(String authorId, {int page = 1, int perPage = 10}) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'filter': 'author.id:$authorId',
        'sort': 'cited_by_count:desc',
        'page': page.toString(),
        'per_page': perPage.toString(),
        'mailto': ApiConstants.contactEmail,
      },
    );
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final int totalCount = data['meta']?['count'] ?? 0;
        
        return {
          'results': results.map((json) => Publication.fromJson(json)).toList(),
          'total_count': totalCount,
        };
      } else {
        throw Exception('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Hàm dùng chung để lấy danh sách từ API
  Future<List<T>> _fetchList<T>(Uri url, T Function(Map<String, dynamic>) mapper) async {
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => mapper(json)).toList();
      } else {
        throw Exception('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
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

  /// Lấy danh sách các chủ đề phổ biến (Concepts)
  Future<List<String>> getPopularTopics() async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/concepts').replace(
      queryParameters: {
        'sort': 'works_count:desc',
        'level': '1',
        'limit': '10',
        'mailto': ApiConstants.contactEmail,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((item) => item['display_name'].toString()).toList();
      } else {
        return ['Artificial Intelligence', 'Data Science', 'Software Engineering', 'Cybersecurity', 'Blockchain'];
      }
    } catch (e) {
      return ['Artificial Intelligence', 'Data Science', 'Software Engineering', 'Cybersecurity', 'Blockchain'];
    }
  }
}
