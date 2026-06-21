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
  final String? userEmail;
  final http.Client client;

  OpenAlexService({this.userEmail, http.Client? client}) : client = client ?? http.Client();

  String get _contactEmail => userEmail ?? ApiConstants.contactEmail;

  /// Tìm kiếm các bài báo theo từ khóa (topic) có hỗ trợ phân trang
  Future<Map<String, dynamic>> searchWorks(String query, {int page = 1, int perPage = 10}) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'search': query,
        'sort': 'cited_by_count:desc',
        'page': page.toString(),
        'per_page': perPage.toString(),
        'mailto': _contactEmail,
      },
    );

    try {
      final response = await client.get(url);
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
        'mailto': _contactEmail,
      },
    );
    
    try {
      final response = await client.get(url);
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

  /// Tìm kiếm nguồn xuất bản (Sources/Journals) với filter là journal
  Future<Map<String, dynamic>> searchSources(String query, {int page = 1, int perPage = 10}) async {
    final Map<String, String> params = {
      'filter': 'type:journal',
      'sort': 'works_count:desc',
      'page': page.toString(),
      'per_page': perPage.toString(),
      'mailto': _contactEmail,
    };

    if (query.isNotEmpty) {
      params['search'] = query;
    }

    final Uri url = Uri.parse('${ApiConstants.baseUrl}/sources').replace(
      queryParameters: params,
    );
    
    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final int totalCount = data['meta']?['count'] ?? 0;
        
        return {
          'results': results.map((json) => Journal.fromJson(json)).toList(),
          'total_count': totalCount,
        };
      } else {
        throw Exception('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Tìm kiếm tổ chức/trường học (Institutions)
  Future<List<Institution>> searchInstitutions(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/institutions').replace(
      queryParameters: {
        'search': query,
        'sort': 'works_count:desc',
        'mailto': _contactEmail,
      },
    );
    return _fetchList(url, (json) => Institution.fromJson(json));
  }

  /// Lấy thông tin chi tiết của một Journal theo ID
  Future<Journal> getJournalDetails(String journalId) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/sources/$journalId').replace(
      queryParameters: {'mailto': _contactEmail},
    );

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        return Journal.fromJson(json.decode(response.body));
      } else {
        throw Exception('Lỗi khi tải chi tiết journal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Lấy danh sách bài báo của một Journal
  Future<Map<String, dynamic>> getWorksByJournal(
    String journalId, {
    int page = 1,
    int perPage = 10,
    String? search,
    int? year,
    int? minCitations,
    String? sortField,
    bool descending = true,
  }) async {
    String filter = 'primary_location.source.id:$journalId';
    if (year != null) {
      filter += ',publication_year:$year';
    }
    if (minCitations != null && minCitations > 0) {
      filter += ',cited_by_count:>$minCitations';
    }

    String sort = 'publication_year:desc,cited_by_count:desc';
    if (sortField != null) {
      sort = '$sortField:${descending ? 'desc' : 'asc'}';
    }

    final Map<String, String> params = {
      'filter': filter,
      'sort': sort,
      'page': page.toString(),
      'per_page': perPage.toString(),
      'mailto': _contactEmail,
    };

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: params,
    );

    try {
      final response = await client.get(url);
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

  /// Lấy dữ liệu xu hướng của một Journal theo ID
  Future<List<TrendData>> getJournalYearlyTrend(String journalId) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'filter': 'primary_location.source.id:$journalId',
        'group_by': 'publication_year',
        'mailto': _contactEmail,
      },
    );

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List groups = data['group_by'] ?? [];
        
        List<TrendData> trends = groups.map((json) => TrendData.fromJson(json)).toList();
        trends.sort((a, b) => a.year.compareTo(b.year));
        return trends;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Lấy sự thay đổi của các chủ đề theo thời gian (Topic Evolution)
  Future<Map<String, List<TrendData>>> getJournalTopicEvolution(String journalId) async {
    try {
      final topTopics = await getJournalTopTopics(journalId);
      Map<String, List<TrendData>> evolution = {};
      
      // Lấy dữ liệu cho top 3 topics
      for (var topic in topTopics.take(3)) {
        final name = topic['name'] as String;
        final id = topic['id'] as String;
        if (id.isEmpty) continue;

        final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
          queryParameters: {
            'filter': 'primary_location.source.id:$journalId,primary_topic.id:$id',
            'group_by': 'publication_year',
            'mailto': _contactEmail,
          },
        );

        final response = await client.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List groups = data['group_by'] ?? [];
          List<TrendData> trends = groups.map((json) => TrendData.fromJson(json)).toList();
          trends.sort((a, b) => a.year.compareTo(b.year));
          evolution[name] = trends;
        }
      }
      return evolution;
    } catch (e) {
      return {};
    }
  }
  Future<List<Map<String, dynamic>>> getJournalTopTopics(String journalId) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'filter': 'primary_location.source.id:$journalId',
        'group_by': 'primary_topic.id',
        'mailto': _contactEmail,
      },
    );

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List groups = data['group_by'] ?? [];
        return groups
            .where((json) => (json['key_display_name'] != null || json['display_name'] != null) && 
                            json['key_display_name'] != 'Unknown' && json['display_name'] != 'Unknown')
            .take(5)
            .map((json) => {
              'id': json['key']?.split('/').last ?? '',
              'name': json['key_display_name'] ?? json['display_name'],
              'count': json['count'] ?? 0,
            }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Tìm kiếm bài báo theo ID tác giả có hỗ trợ phân trang
  Future<Map<String, dynamic>> getWorksByAuthor(String authorId, {int page = 1, int perPage = 10}) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'filter': 'author.id:$authorId',
        'sort': 'cited_by_count:desc',
        'page': page.toString(),
        'per_page': perPage.toString(),
        'mailto': _contactEmail,
      },
    );
    
    try {
      final response = await client.get(url);
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
      final response = await client.get(url);
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
        'mailto': _contactEmail,
      },
    );

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List groups = data['group_by'] ?? [];
        
        List<TrendData> trends = groups.map((json) => TrendData.fromJson(json)).toList();
        trends.sort((a, b) => a.year.compareTo(b.year));
        
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

  /// Lấy danh sách các từ khóa phổ biến (Concepts) của một chủ đề
  Future<List<Map<String, dynamic>>> getTopKeywords(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'search': query,
        'group_by': 'concepts.id',
        'mailto': ApiConstants.contactEmail,
      },
    );

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List groups = data['group_by'] ?? [];
        
        // Lọc bỏ các mục không có tên hoặc là "Unknown"
        return groups
            .where((json) => json['display_name'] != null && 
                            json['display_name'].toString().isNotEmpty &&
                            json['display_name'] != 'Unknown')
            .take(10)
            .map((json) => {
              'name': json['display_name'],
              'count': json['count'] ?? 0,
            }).toList();
      } else {
        throw Exception('Lỗi khi tải dữ liệu từ khóa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API: $e');
    }
  }

  /// Lấy dữ liệu bài báo theo quốc gia
  Future<List<Map<String, dynamic>>> getCountryOutput(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'search': query,
        'group_by': 'institutions.country_code',
        'mailto': _contactEmail,
      },
    );

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List groups = data['group_by'] ?? [];
        
        return groups
            .where((json) => json['key'] != null && json['key'] != 'Unknown')
            .map((json) {
              String rawName = json['display_name'] ?? '';
              if (rawName.startsWith('http')) {
                final uri = Uri.parse(rawName);
                rawName = uri.pathSegments.last;
              }
              
              return {
                'country_code': json['key'],
                'name': rawName.isNotEmpty ? rawName : json['key'],
                'count': json['count'] ?? 0,
              };
            }).toList();
      } else {
        throw Exception('Lỗi khi tải dữ liệu quốc gia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API: $e');
    }
  }

  /// Lấy danh sách các tạp chí phổ biến nhất cho chủ đề
  Future<List<Map<String, dynamic>>> getTopJournals(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'search': query,
        'group_by': 'primary_location.source.id',
        'mailto': _contactEmail,
      },
    );

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List groups = data['group_by'] ?? [];
        
        return groups
            .where((json) => json['display_name'] != null && 
                            json['display_name'].toString().isNotEmpty &&
                            json['display_name'] != 'Unknown Journal' &&
                            json['key'] != 'null')
            .take(10)
            .map((json) => {
              'name': json['display_name'],
              'count': json['count'] ?? 0,
            }).toList();
      } else {
        throw Exception('Lỗi khi tải dữ liệu tạp chí: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API: $e');
    }
  }

  /// Lấy danh sách tác giả hàng đầu cho chủ đề
  Future<List<Map<String, dynamic>>> getTopAuthorsByTopic(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'search': query,
        'group_by': 'authorships.author.id',
        'mailto': _contactEmail,
      },
    );

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List groups = data['group_by'] ?? [];
        
        return groups
            .where((json) => json['display_name'] != null && 
                            json['display_name'].toString().isNotEmpty &&
                            json['key'] != 'null')
            .take(10)
            .map((json) => {
              'name': json['display_name'],
              'count': json['count'] ?? 0,
            }).toList();
      } else {
        throw Exception('Lỗi khi tải dữ liệu tác giả: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API: $e');
    }
  }

  /// Lấy danh sách các bài báo có ảnh hưởng nhất (tên thật)
  Future<List<Map<String, dynamic>>> getTopInfluentialWorks(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'search': query,
        'sort': 'cited_by_count:desc',
        'per_page': '5',
        'mailto': _contactEmail,
      },
    );

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        
        return results.map((json) => {
          'name': json['display_name'] ?? 'Ấn phẩm chưa xác định',
          'count': json['cited_by_count'] ?? 0,
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Lấy dữ liệu phân bổ chất lượng bài báo (Dựa trên Citation Percentile thực tế)
  Future<List<Map<String, dynamic>>> getQuartileDistribution(String query) async {
    // Thay vì dùng group_by (vốn không hỗ trợ Quartile trực tiếp), 
    // ta lấy top 50 bài báo và tính toán phân bổ dựa trên percentile thực tế từ OpenAlex.
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'search': query,
        'sort': 'cited_by_count:desc',
        'per_page': '50',
        'select': 'citation_normalized_percentile',
        'mailto': _contactEmail,
      },
    );

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        
        int q1 = 0; // 75-100
        int q2 = 0; // 50-75
        int q3 = 0; // 25-50
        int q4 = 0; // 0-25
        
        for (var work in results) {
          final percentile = work['citation_normalized_percentile']?['value'];
          if (percentile != null) {
            double val = (percentile as num).toDouble();
            if (val >= 75) q1++;
            else if (val >= 50) q2++;
            else if (val >= 25) q3++;
            else q4++;
          }
        }
        
        // Nếu không có dữ liệu percentile (ví dụ bài báo quá mới), trả về rỗng để UI xử lý
        int total = q1 + q2 + q3 + q4;
        if (total == 0) return [];

        return [
          {'name': 'Q1 (Top 25%)', 'count': q1, 'percentage': (q1 / total * 100).round(), 'color': '#15803D'},
          {'name': 'Q2 (50-75%)', 'count': q2, 'percentage': (q2 / total * 100).round(), 'color': '#B45309'},
          {'name': 'Q3 (25-50%)', 'count': q3, 'percentage': (q3 / total * 100).round(), 'color': '#B8422E'},
          {'name': 'Q4 (Bottom 25%)', 'count': q4, 'percentage': (q4 / total * 100).round(), 'color': '#6C7278'},
        ];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Xếp hạng tổ chức (Institution Ranking)
  Future<List<Map<String, dynamic>>> getInstitutionRanking(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}').replace(
      queryParameters: {
        'search': query,
        'group_by': 'authorships.institutions.id',
        'mailto': _contactEmail,
      },
    );

    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List groups = data['group_by'] ?? [];
        
        return groups.take(10).map((json) => {
          'name': json['display_name'] ?? 'Tổ chức chưa xác định',
          'count': json['count'] ?? 0,
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
