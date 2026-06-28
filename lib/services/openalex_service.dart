import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/publication_model.dart';
import '../models/trend_data_model.dart';
import '../models/author_model.dart';
import '../models/journal_model.dart';
import '../models/institution_model.dart';
import '../utils/api_constants.dart';

/// Lớp hỗ trợ lưu trữ cache đơn giản
class _CacheEntry {
  final dynamic data;
  final DateTime expiryTime;

  _CacheEntry(this.data, this.expiryTime);

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

class _OpenAlexHttpException implements Exception {
  final int statusCode;

  _OpenAlexHttpException(this.statusCode);

  @override
  String toString() => 'Lỗi API: $statusCode';
}

/// Dịch vụ kết nối và lấy dữ liệu từ OpenAlex API
class OpenAlexService {
  final String? userEmail;
  final String? apiKey;
  final http.Client client;
  final Duration minRequestInterval;
  final Duration requestTimeout;

  // Bộ nhớ đệm trong RAM
  static final Map<String, _CacheEntry> _cache = {};
  static final Map<String, Future<dynamic>> _inFlightRequests = {};
  static Future<void> _requestQueue = Future.value();
  static DateTime _nextAllowedRequestTime = DateTime.fromMillisecondsSinceEpoch(
    0,
  );
  static DateTime? _rateLimitedUntil;

  OpenAlexService({
    this.userEmail,
    this.apiKey,
    http.Client? client,
    Duration? minRequestInterval,
    Duration? requestTimeout,
  }) : client = client ?? http.Client(),
       minRequestInterval =
           minRequestInterval ??
           const Duration(milliseconds: ApiConstants.minRequestIntervalMs),
       requestTimeout =
           requestTimeout ??
           const Duration(seconds: ApiConstants.requestTimeoutSeconds);

  String get _contactEmail => userEmail ?? ApiConstants.contactEmail;
  String get _apiKey => apiKey ?? ApiConstants.apiKey;

  static void resetForTesting() {
    _cache.clear();
    _inFlightRequests.clear();
    _requestQueue = Future.value();
    _nextAllowedRequestTime = DateTime.fromMillisecondsSinceEpoch(0);
    _rateLimitedUntil = null;
  }

  /// Xếp hàng request để toàn app không bắn nhiều request OpenAlex cùng lúc.
  Future<T> _runRateLimited<T>(Future<T> Function() action) {
    final completer = Completer<T>();

    _requestQueue = _requestQueue.catchError((_) {}).then((_) async {
      final now = DateTime.now();
      final blockedUntil = _rateLimitedUntil;
      DateTime waitUntil = _nextAllowedRequestTime;

      if (blockedUntil != null && blockedUntil.isAfter(waitUntil)) {
        waitUntil = blockedUntil;
      }

      if (waitUntil.isAfter(now)) {
        await Future.delayed(waitUntil.difference(now));
      }

      try {
        final result = await action();
        completer.complete(result);
      } catch (e, stackTrace) {
        completer.completeError(e, stackTrace);
      } finally {
        _nextAllowedRequestTime = DateTime.now().add(minRequestInterval);
      }
    });

    return completer.future;
  }

  Duration? _retryAfterDelay(http.Response response) {
    final retryAfter = response.headers['retry-after'];
    if (retryAfter == null || retryAfter.isEmpty) return null;

    final seconds = int.tryParse(retryAfter);
    if (seconds == null) return null;

    return Duration(seconds: seconds);
  }

  Duration _capRetryDelay(Duration delay) {
    const maxDelay = Duration(seconds: ApiConstants.maxRetryDelaySeconds);
    return delay > maxDelay ? maxDelay : delay;
  }

  void _rememberRateLimit(Duration delay) {
    _rateLimitedUntil = DateTime.now().add(_capRetryDelay(delay));
  }

  /// Hàm hỗ trợ thực hiện GET request với cơ chế Retry (Exponential Backoff) và Cache
  Future<dynamic> _getWithRetryAndCache(Uri url, {bool useCache = true}) async {
    // Tự động thêm API Key hoặc mailto vào URL nếu chưa có
    Map<String, String> queryParams = Map.from(url.queryParameters);
    if (_apiKey.isNotEmpty) {
      queryParams['api_key'] = _apiKey;
    } else if (!queryParams.containsKey('mailto')) {
      queryParams['mailto'] = _contactEmail;
    }

    final Uri finalUrl = url.replace(queryParameters: queryParams);
    final String cacheKey = finalUrl.toString();

    // 1. Kiểm tra cache trước
    if (useCache && _cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        return entry.data;
      } else {
        _cache.remove(cacheKey);
      }
    }

    if (_inFlightRequests.containsKey(cacheKey)) {
      return _inFlightRequests[cacheKey]!;
    }

    final requestFuture = _getWithRetry(finalUrl, cacheKey, useCache: useCache);
    _inFlightRequests[cacheKey] = requestFuture;

    try {
      return await requestFuture;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  Future<dynamic> _getWithRetry(
    Uri finalUrl,
    String cacheKey, {
    required bool useCache,
  }) async {
    int retryCount = 0;
    Duration waitTime = const Duration(seconds: 1);

    while (retryCount <= ApiConstants.maxRetries) {
      try {
        final response = await _runRateLimited(
          () => client.get(finalUrl).timeout(requestTimeout),
        );

        if (response.statusCode == 200) {
          final decodedData = json.decode(response.body);

          // 2. Lưu vào cache nếu thành công
          if (useCache) {
            _cache[cacheKey] = _CacheEntry(
              decodedData,
              DateTime.now().add(
                const Duration(minutes: ApiConstants.defaultCacheMinutes),
              ),
            );
          }
          return decodedData;
        } else if (response.statusCode == 429) {
          // Gặp lỗi Too Many Requests - Đợi rồi thử lại
          retryCount++;
          if (retryCount > ApiConstants.maxRetries) {
            throw Exception(
              'Lỗi API 429: Đã thử lại $retryCount lần nhưng vẫn thất bại.',
            );
          }

          final retryDelay = _retryAfterDelay(response) ?? waitTime;
          _rememberRateLimit(retryDelay);

          await Future.delayed(_capRetryDelay(retryDelay));
          waitTime = _capRetryDelay(waitTime * 2); // Gấp đôi thời gian chờ
          continue;
        } else {
          throw _OpenAlexHttpException(response.statusCode);
        }
      } catch (e) {
        if (e is _OpenAlexHttpException) rethrow;
        if (e is Exception && e.toString().contains('429')) rethrow;

        // Các lỗi kết nối khác cũng có thể thử lại nhẹ nhàng
        retryCount++;
        if (retryCount > ApiConstants.maxRetries) rethrow;
        await Future.delayed(_capRetryDelay(waitTime));
        waitTime = _capRetryDelay(waitTime * 2);
      }
    }
  }

  /// Tìm kiếm các bài báo theo từ khóa (topic) có hỗ trợ phân trang
  Future<Map<String, dynamic>> searchWorks(
    String query, {
    int page = 1,
    int perPage = 10,
  }) async {
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'search': query,
            'sort': 'cited_by_count:desc',
            'page': page.toString(),
            'per_page': perPage.toString(),
            'select':
                'id,display_name,title,publication_year,cited_by_count,authorships,primary_location',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List results = data['results'] ?? [];
      final int totalCount = data['meta']?['count'] ?? 0;

      return {
        'results': results.map((json) => Publication.fromJson(json)).toList(),
        'total_count': totalCount,
      };
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm bài báo: $e');
    }
  }

  /// Tìm kiếm tác giả (Authors) có hỗ trợ phân trang
  Future<Map<String, dynamic>> searchAuthors(
    String query, {
    int page = 1,
    int perPage = 10,
  }) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/authors').replace(
      queryParameters: {
        'search': query,
        'sort': 'works_count:desc',
        'page': page.toString(),
        'per_page': perPage.toString(),
        'select':
            'id,display_name,last_known_institution,works_count,cited_by_count',
      },
    );

    try {
      final data = await _getWithRetryAndCache(url);
      final List results = data['results'] ?? [];
      final int totalCount = data['meta']?['count'] ?? 0;

      return {
        'results': results.map((json) => Author.fromJson(json)).toList(),
        'total_count': totalCount,
      };
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm tác giả: $e');
    }
  }

  /// Tìm kiếm nguồn xuất bản (Sources/Journals) với filter là journal
  Future<Map<String, dynamic>> searchSources(
    String query, {
    int page = 1,
    int perPage = 10,
  }) async {
    final Map<String, String> params = {
      'filter': 'type:journal',
      'sort': 'works_count:desc',
      'page': page.toString(),
      'per_page': perPage.toString(),
      'select':
          'id,display_name,host_organization_name,type,works_count,cited_by_count',
    };

    if (query.isNotEmpty) {
      params['search'] = query;
    }

    final Uri url = Uri.parse(
      '${ApiConstants.baseUrl}/sources',
    ).replace(queryParameters: params);

    try {
      final data = await _getWithRetryAndCache(url);
      final List results = data['results'] ?? [];
      final int totalCount = data['meta']?['count'] ?? 0;

      return {
        'results': results.map((json) => Journal.fromJson(json)).toList(),
        'total_count': totalCount,
      };
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm nguồn: $e');
    }
  }

  /// Tìm kiếm tổ chức/trường học (Institutions)
  Future<List<Institution>> searchInstitutions(String query) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/institutions').replace(
      queryParameters: {
        'search': query,
        'sort': 'works_count:desc',
        'select':
            'id,display_name,type,country_code,works_count,cited_by_count',
      },
    );

    try {
      final data = await _getWithRetryAndCache(url);
      final List results = data['results'] ?? [];
      return results.map((json) => Institution.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm tổ chức: $e');
    }
  }

  /// Lấy thông tin chi tiết của một Journal theo ID
  Future<Journal> getJournalDetails(String journalId) async {
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/sources/$journalId');

    try {
      final data = await _getWithRetryAndCache(url);
      return Journal.fromJson(data);
    } catch (e) {
      throw Exception('Lỗi khi tải chi tiết journal: $e');
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
      'select':
          'id,display_name,title,publication_year,cited_by_count,authorships,primary_location',
    };

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    final Uri url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
    ).replace(queryParameters: params);

    try {
      final data = await _getWithRetryAndCache(url);
      final List results = data['results'] ?? [];
      final int totalCount = data['meta']?['count'] ?? 0;

      return {
        'results': results.map((json) => Publication.fromJson(json)).toList(),
        'total_count': totalCount,
      };
    } catch (e) {
      throw Exception('Lỗi khi tải bài báo theo journal: $e');
    }
  }

  /// Lấy dữ liệu xu hướng của một Journal theo ID
  Future<List<TrendData>> getJournalYearlyTrend(String journalId) async {
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': 'primary_location.source.id:$journalId',
            'group_by': 'publication_year',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];

      List<TrendData> trends = groups
          .map((json) => TrendData.fromJson(json))
          .toList();
      trends.sort((a, b) => a.year.compareTo(b.year));
      return trends;
    } catch (e) {
      return [];
    }
  }

  /// Lấy sự thay đổi của các chủ đề theo thời gian (Topic Evolution)
  Future<Map<String, List<TrendData>>> getJournalTopicEvolution(
    String journalId,
  ) async {
    try {
      final topTopics = await getJournalTopTopics(journalId);
      Map<String, List<TrendData>> evolution = {};

      // Lấy dữ liệu cho top 3 topics
      for (var topic in topTopics.take(3)) {
        final name = topic['name'] as String;
        final id = topic['id'] as String;
        if (id.isEmpty) continue;

        final Uri url =
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
            ).replace(
              queryParameters: {
                'filter':
                    'primary_location.source.id:$journalId,primary_topic.id:$id',
                'group_by': 'publication_year',
              },
            );

        final data = await _getWithRetryAndCache(url);
        final List groups = data['group_by'] ?? [];
        List<TrendData> trends = groups
            .map((json) => TrendData.fromJson(json))
            .toList();
        trends.sort((a, b) => a.year.compareTo(b.year));
        evolution[name] = trends;
      }
      return evolution;
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getJournalTopTopics(
    String journalId,
  ) async {
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': 'primary_location.source.id:$journalId',
            'group_by': 'primary_topic.id',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];
      return groups
          .where(
            (json) =>
                (json['key_display_name'] != null ||
                    json['display_name'] != null) &&
                json['key_display_name'] != 'Unknown' &&
                json['display_name'] != 'Unknown',
          )
          .take(5)
          .map(
            (json) => {
              'id': json['key']?.split('/').last ?? '',
              'name': json['key_display_name'] ?? json['display_name'],
              'count': json['count'] ?? 0,
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Tìm kiếm bài báo theo ID tác giả có hỗ trợ phân trang
  Future<Map<String, dynamic>> getWorksByAuthor(
    String authorId, {
    int page = 1,
    int perPage = 10,
  }) async {
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': 'author.id:$authorId',
            'sort': 'cited_by_count:desc',
            'page': page.toString(),
            'per_page': perPage.toString(),
            'select':
                'id,display_name,title,publication_year,cited_by_count,authorships,primary_location',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List results = data['results'] ?? [];
      final int totalCount = data['meta']?['count'] ?? 0;

      return {
        'results': results.map((json) => Publication.fromJson(json)).toList(),
        'total_count': totalCount,
      };
    } catch (e) {
      throw Exception('Lỗi khi tải bài báo theo tác giả: $e');
    }
  }

  /// Lấy dữ liệu xu hướng số lượng bài báo theo năm của một chủ đề
  Future<List<TrendData>> getYearlyTrend(String query) async {
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {'search': query, 'group_by': 'publication_year'},
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];

      List<TrendData> trends = groups
          .map((json) => TrendData.fromJson(json))
          .toList();
      trends.sort((a, b) => a.year.compareTo(b.year));

      if (trends.length > 10) {
        trends = trends.sublist(trends.length - 10);
      }

      return trends;
    } catch (e) {
      throw Exception('Lỗi khi tải dữ liệu xu hướng: $e');
    }
  }

  /// Lấy danh sách các từ khóa phổ biến (Concepts) của một chủ đề
  Future<List<Map<String, dynamic>>> getTopKeywords(String query) async {
    final Uri url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
    ).replace(queryParameters: {'search': query, 'group_by': 'concepts.id'});

    try {
      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];

      return groups
          .where(
            (json) =>
                json['display_name'] != null &&
                json['display_name'].toString().isNotEmpty &&
                json['display_name'] != 'Unknown',
          )
          .take(10)
          .map(
            (json) => {
              'name': json['display_name'],
              'count': json['count'] ?? 0,
            },
          )
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải dữ liệu từ khóa: $e');
    }
  }

  /// Lấy dữ liệu bài báo theo quốc gia
  Future<List<Map<String, dynamic>>> getCountryOutput(String query) async {
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'search': query,
            'group_by': 'institutions.country_code',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
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
          })
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải dữ liệu quốc gia: $e');
    }
  }

  /// Lấy danh sách các tạp chí phổ biến nhất cho chủ đề
  Future<List<Map<String, dynamic>>> getTopJournals(String query) async {
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'search': query,
            'group_by': 'primary_location.source.id',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];

      return groups
          .where(
            (json) =>
                json['display_name'] != null &&
                json['display_name'].toString().isNotEmpty &&
                json['display_name'] != 'Unknown Journal' &&
                json['key'] != 'null',
          )
          .take(10)
          .map(
            (json) => {
              'name': json['display_name'],
              'count': json['count'] ?? 0,
            },
          )
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải dữ liệu tạp chí: $e');
    }
  }

  /// Lấy danh sách tác giả hàng đầu cho chủ đề
  Future<List<Map<String, dynamic>>> getTopAuthorsByTopic(String query) async {
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'search': query,
            'group_by': 'authorships.author.id',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];

      return groups
          .where(
            (json) =>
                json['display_name'] != null &&
                json['display_name'].toString().isNotEmpty &&
                json['key'] != 'null',
          )
          .take(10)
          .map(
            (json) => {
              'name': json['display_name'],
              'count': json['count'] ?? 0,
            },
          )
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải dữ liệu tác giả theo chủ đề: $e');
    }
  }

  /// Lấy danh sách các bài báo có ảnh hưởng nhất (tên thật)
  Future<List<Map<String, dynamic>>> getTopInfluentialWorks(
    String query,
  ) async {
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'search': query,
            'sort': 'cited_by_count:desc',
            'per_page': '5',
            'select': 'id,display_name,cited_by_count',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List results = data['results'] ?? [];

      return results
          .map(
            (json) => {
              'name': json['display_name'] ?? 'Ấn phẩm chưa xác định',
              'count': json['cited_by_count'] ?? 0,
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Lấy dữ liệu phân bổ chất lượng bài báo (Dựa trên Citation Percentile thực tế)
  Future<List<Map<String, dynamic>>> getQuartileDistribution(
    String query,
  ) async {
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'search': query,
            'sort': 'cited_by_count:desc',
            'per_page': '50',
            'select': 'citation_normalized_percentile',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List results = data['results'] ?? [];

      int q1 = 0; // 75-100
      int q2 = 0; // 50-75
      int q3 = 0; // 25-50
      int q4 = 0; // 0-25

      for (var work in results) {
        final percentile = work['citation_normalized_percentile']?['value'];
        if (percentile != null) {
          double val = (percentile as num).toDouble();
          if (val >= 75) {
            q1++;
          } else if (val >= 50) {
            q2++;
          } else if (val >= 25) {
            q3++;
          } else {
            q4++;
          }
        }
      }

      int total = q1 + q2 + q3 + q4;
      if (total == 0) return [];

      return [
        {
          'name': 'Q1 (Top 25%)',
          'count': q1,
          'percentage': (q1 / total * 100).round(),
          'color': '#15803D',
        },
        {
          'name': 'Q2 (50-75%)',
          'count': q2,
          'percentage': (q2 / total * 100).round(),
          'color': '#B45309',
        },
        {
          'name': 'Q3 (25-50%)',
          'count': q3,
          'percentage': (q3 / total * 100).round(),
          'color': '#B8422E',
        },
        {
          'name': 'Q4 (Bottom 25%)',
          'count': q4,
          'percentage': (q4 / total * 100).round(),
          'color': '#6C7278',
        },
      ];
    } catch (e) {
      return [];
    }
  }

  /// Xếp hạng tổ chức (Institution Ranking)
  Future<List<Map<String, dynamic>>> getInstitutionRanking(String query) async {
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'search': query,
            'group_by': 'authorships.institutions.id',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];

      return groups
          .take(10)
          .map(
            (json) => {
              'name': json['display_name'] ?? 'Tổ chức chưa xác định',
              'count': json['count'] ?? 0,
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }
}
