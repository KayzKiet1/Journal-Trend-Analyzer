import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/publication_model.dart';
import '../models/trend_data_model.dart';
import '../models/journal_model.dart';
import '../models/research_topic_model.dart';
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
  final String message;

  _OpenAlexHttpException(this.statusCode, [this.message = '']);

  @override
  String toString() {
    if (message.isEmpty) return 'Lỗi API: $statusCode';
    return 'Lỗi API $statusCode: $message';
  }
}

/// Dịch vụ kết nối và lấy dữ liệu từ OpenAlex API
class OpenAlexService {
  static const String _workSelectFields =
      'id,display_name,title,publication_year,publication_date,cited_by_count,'
      'authorships,primary_location,doi,abstract_inverted_index,topics,concepts';

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

  String _openAlexId(String idOrUrl) {
    final parsed = Uri.tryParse(idOrUrl);
    if (parsed != null && parsed.pathSegments.isNotEmpty) {
      return parsed.pathSegments.last;
    }
    return idOrUrl.split('/').last;
  }

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

  bool _isTransientServerError(int statusCode) {
    return statusCode == 502 || statusCode == 503 || statusCode == 504;
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
              'OpenAlex đang giới hạn tốc độ truy cập (429). Vui lòng đợi một chút rồi thử lại.',
            );
          }

          final retryDelay = _retryAfterDelay(response) ?? waitTime;
          _rememberRateLimit(retryDelay);

          await Future.delayed(_capRetryDelay(retryDelay));
          waitTime = _capRetryDelay(waitTime * 2); // Gấp đôi thời gian chờ
          continue;
        } else if (_isTransientServerError(response.statusCode)) {
          retryCount++;
          if (retryCount > ApiConstants.maxRetries) {
            throw _OpenAlexHttpException(
              response.statusCode,
              'OpenAlex đang xử lý quá tải hoặc timeout. Vui lòng thử lại sau.',
            );
          }

          await Future.delayed(_capRetryDelay(waitTime));
          waitTime = _capRetryDelay(waitTime * 2);
          continue;
        } else {
          throw _OpenAlexHttpException(
            response.statusCode,
            _apiErrorMessage(response),
          );
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

  String _apiErrorMessage(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      final message = decoded['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
      final error = decoded['error']?.toString();
      if (error != null && error.isNotEmpty) return error;
    } catch (_) {
      // Body is not always JSON.
    }
    return response.reasonPhrase ?? 'Không rõ nguyên nhân';
  }

  /// Tìm kiếm trực tiếp nguồn xuất bản (Sources/Journals).
  ///
  /// Query được gửi vào endpoint /sources với filter type:journal.
  Future<Map<String, dynamic>> searchSources(
    String query, {
    int page = 1,
    int perPage = 10,
    String? topicId,
    List<String>? topicIds,
  }) async {
    final trimmedQuery = query.trim();

    final Map<String, String> params = {
      'filter': 'type:journal',
      'sort': 'works_count:desc',
      'page': page.toString(),
      'per_page': perPage.toString(),
      'select':
          'id,display_name,host_organization_name,type,works_count,cited_by_count',
    };

    if (trimmedQuery.isNotEmpty) {
      params['search'] = trimmedQuery;
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

  Future<Map<String, dynamic>> searchJournalSourcesByTopic(
    String topicQuery, {
    String? topicId,
    List<String>? topicIds,
    int page = 1,
    int perPage = 10,
  }) async {
    final resolvedTopicFilter = _topicFilterValue(
      topicId: topicId,
      topicIds: topicIds,
    );
    final topicFilter = resolvedTopicFilter?.isNotEmpty == true
        ? resolvedTopicFilter
        : await _resolveTopicId(topicQuery);
    if (topicFilter == null || topicFilter.isEmpty) {
      return {'results': <Journal>[], 'total_count': 0};
    }

    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter':
                'primary_topic.id:$topicFilter,primary_location.source.type:journal',
            'group_by': 'primary_location.source.id',
            'page': page.toString(),
            'per_page': perPage.toString(),
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];
      final journals = groups
          .where((group) {
            final key = group['key']?.toString() ?? '';
            return key.isNotEmpty && key != 'unknown';
          })
          .map(
            (group) => Journal(
              id: group['key']?.toString() ?? '',
              name:
                  group['key_display_name']?.toString() ??
                  group['display_name']?.toString() ??
                  'Unknown Journal',
              type: 'journal',
              worksCount: (group['count'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList();

      return {'results': journals, 'total_count': journals.length};
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm journal theo topic: $e');
    }
  }

  Future<List<ResearchTopic>> searchTopics(
    String query, {
    int perPage = 10,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) return [];

    final Uri url = Uri.parse(
      '${ApiConstants.baseUrl}/autocomplete/topics',
    ).replace(queryParameters: {'q': trimmedQuery});

    try {
      final data = await _getWithRetryAndCache(url);
      final List results = data['results'] ?? [];
      final topics = results
          .map((json) => ResearchTopic.fromJson(json))
          .where((topic) => topic.id.isNotEmpty && topic.name.isNotEmpty)
          .toList();
      final nameMatches = _topicsMatchingQueryName(topics, trimmedQuery);
      final suggestions = nameMatches.isNotEmpty ? nameMatches : topics;
      suggestions.sort((a, b) => b.worksCount.compareTo(a.worksCount));
      return suggestions.take(perPage).toList();
    } catch (e) {
      throw Exception('Lỗi khi tìm topic: $e');
    }
  }

  Future<String?> _resolveTopicId(String topicQuery) async {
    final topics = await searchTopics(topicQuery, perPage: 1);
    if (topics.isEmpty) return null;
    return _openAlexId(topics.first.id);
  }

  String? _topicFilterValue({String? topicId, List<String>? topicIds}) {
    final ids =
        <String>[...?topicIds, if (topicId != null) ...topicId.split('|')]
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .map(_openAlexId)
            .toSet()
            .toList();

    if (ids.isEmpty) return null;
    return ids.join('|');
  }

  String _openAlexKeywordId(String idOrUrl) {
    final parsed = Uri.tryParse(idOrUrl);
    if (parsed != null && parsed.pathSegments.isNotEmpty) {
      return parsed.pathSegments.last;
    }
    return idOrUrl.split('/').last;
  }

  String? _topicWorksFilter(List<String> topicIds) {
    final topicFilter = _topicFilterValue(topicIds: topicIds);
    if (topicFilter == null || topicFilter.isEmpty) return null;
    return 'primary_topic.id:$topicFilter,primary_location.source.type:journal';
  }

  Future<Map<String, dynamic>> getWorksByTopics(
    List<String> topicIds, {
    int page = 1,
    int perPage = 20,
  }) async {
    final filter = _topicWorksFilter(topicIds);
    if (filter == null) return {'results': <Publication>[], 'total_count': 0};

    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': filter,
            'sort': 'cited_by_count:desc',
            'page': page.toString(),
            'per_page': perPage.toString(),
            'select': _workSelectFields,
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
      throw Exception('Lỗi khi tải công bố theo topic: $e');
    }
  }

  Future<List<TrendData>> getTopicPublicationTrend(
    List<String> topicIds,
  ) async {
    final filter = _topicWorksFilter(topicIds);
    if (filter == null) return [];

    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': filter,
            'group_by': 'publication_year',
            'per_page': '200',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];
      final trends = groups
          .map((json) => TrendData.fromJson(json))
          .where((trend) => trend.year > 0)
          .toList();
      trends.sort((a, b) => a.year.compareTo(b.year));
      return trends;
    } catch (e) {
      throw Exception('Lỗi khi tải xu hướng công bố theo topic: $e');
    }
  }

  Future<Map<String, int>> getTopicTopAuthors(List<String> topicIds) async {
    return _getTopicGroupedCounts(topicIds, 'authorships.author.id');
  }

  Future<Map<String, int>> getTopicTopJournals(List<String> topicIds) async {
    return _getTopicGroupedCounts(topicIds, 'primary_location.source.id');
  }

  Future<List<Map<String, dynamic>>> getTopicTopKeywords(
    List<String> topicIds, {
    int perPage = 10,
  }) {
    return _getTopicKeywordGroups(topicIds, perPage: perPage);
  }

  Future<List<Map<String, dynamic>>> getTopicTrendingKeywords(
    List<String> topicIds, {
    required int fromYear,
    int perPage = 10,
  }) {
    return _getTopicKeywordGroups(
      topicIds,
      extraFilter: 'from_publication_date:$fromYear-01-01',
      perPage: perPage,
    );
  }

  Future<Map<String, List<TrendData>>> getTopicKeywordTrends(
    List<String> topicIds,
    List<String> keywordIds, {
    int perKeyword = 3,
  }) async {
    final filter = _topicWorksFilter(topicIds);
    if (filter == null) return {};

    final trends = <String, List<TrendData>>{};
    for (final rawKeywordId in keywordIds.take(perKeyword)) {
      final keywordId = _openAlexKeywordId(rawKeywordId);
      if (keywordId.isEmpty) continue;

      final Uri url =
          Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
          ).replace(
            queryParameters: {
              'filter': '$filter,keywords.id:$keywordId',
              'group_by': 'publication_year',
              'per_page': '200',
            },
          );

      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];
      final keywordTrends =
          groups
              .map((json) => TrendData.fromJson(json))
              .where((trend) => trend.year > 0)
              .toList()
            ..sort((a, b) => a.year.compareTo(b.year));
      trends[keywordId] = keywordTrends;
    }

    return trends;
  }

  Future<List<TrendData>> getKeywordPublicationTrend(
    List<String> topicIds,
    String keywordId,
  ) async {
    final trends = await getTopicKeywordTrends(topicIds, [
      keywordId,
    ], perKeyword: 1);
    return trends[_openAlexKeywordId(keywordId)] ?? [];
  }

  Future<List<Map<String, dynamic>>> getKeywordTopJournals(
    List<String> topicIds,
    String keywordId, {
    int perPage = 8,
  }) {
    return _getKeywordGroupedCounts(
      topicIds,
      keywordId,
      'primary_location.source.id',
      perPage: perPage,
    );
  }

  Future<List<Map<String, dynamic>>> getKeywordTopAuthors(
    List<String> topicIds,
    String keywordId, {
    int perPage = 8,
  }) {
    return _getKeywordGroupedCounts(
      topicIds,
      keywordId,
      'authorships.author.id',
      perPage: perPage,
    );
  }

  Future<Map<String, dynamic>> getWorksByKeyword(
    List<String> topicIds,
    String keywordId, {
    int page = 1,
    int perPage = 10,
  }) async {
    final filter = _keywordWorksFilter(topicIds, keywordId);
    if (filter == null) return {'results': <Publication>[], 'total_count': 0};

    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': filter,
            'sort': 'cited_by_count:desc',
            'page': page.toString(),
            'per_page': perPage.toString(),
            'select': _workSelectFields,
          },
        );

    final data = await _getWithRetryAndCache(url);
    final List results = data['results'] ?? [];
    final int totalCount = data['meta']?['count'] ?? 0;

    return {
      'results': results.map((json) => Publication.fromJson(json)).toList(),
      'total_count': totalCount,
    };
  }

  Future<List<Map<String, dynamic>>> _getKeywordGroupedCounts(
    List<String> topicIds,
    String keywordId,
    String groupBy, {
    int perPage = 8,
  }) async {
    final filter = _keywordWorksFilter(topicIds, keywordId);
    if (filter == null) return [];

    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': filter,
            'group_by': groupBy,
            'per_page': perPage.toString(),
          },
        );

    final data = await _getWithRetryAndCache(url);
    final List groups = data['group_by'] ?? [];
    return groups
        .where((group) {
          final name = group['key_display_name']?.toString() ?? '';
          return name.isNotEmpty && name.toLowerCase() != 'unknown';
        })
        .map(
          (group) => {
            'id': group['key']?.toString() ?? '',
            'name': group['key_display_name']?.toString() ?? '',
            'count': (group['count'] as num?)?.toInt() ?? 0,
          },
        )
        .toList();
  }

  String? _keywordWorksFilter(List<String> topicIds, String keywordId) {
    final baseFilter = _topicWorksFilter(topicIds);
    final normalizedKeywordId = _openAlexKeywordId(keywordId);
    if (baseFilter == null || normalizedKeywordId.isEmpty) return null;
    return '$baseFilter,keywords.id:$normalizedKeywordId';
  }

  Future<List<Map<String, dynamic>>> _getTopicKeywordGroups(
    List<String> topicIds, {
    String? extraFilter,
    int perPage = 10,
  }) async {
    final filter = _topicWorksFilter(topicIds);
    if (filter == null) return [];

    final combinedFilter = extraFilter == null
        ? filter
        : '$filter,$extraFilter';
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': combinedFilter,
            'group_by': 'keywords.id',
            'per_page': perPage.toString(),
          },
        );

    final data = await _getWithRetryAndCache(url);
    final List groups = data['group_by'] ?? [];
    return groups
        .where((group) {
          final name = group['key_display_name']?.toString() ?? '';
          return name.isNotEmpty && name.toLowerCase() != 'unknown';
        })
        .map(
          (group) => {
            'id': group['key']?.toString() ?? '',
            'name': group['key_display_name']?.toString() ?? '',
            'count': (group['count'] as num?)?.toInt() ?? 0,
          },
        )
        .toList();
  }

  Future<Map<String, int>> _getTopicGroupedCounts(
    List<String> topicIds,
    String groupBy,
  ) async {
    final filter = _topicWorksFilter(topicIds);
    if (filter == null) return {};

    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': filter,
            'group_by': groupBy,
            'per_page': '5',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];
      return Map.fromEntries(
        groups
            .where((group) {
              final name = group['key_display_name']?.toString() ?? '';
              return name.isNotEmpty && name.toLowerCase() != 'unknown';
            })
            .map(
              (group) => MapEntry(
                group['key_display_name'].toString(),
                (group['count'] as num?)?.toInt() ?? 0,
              ),
            ),
      );
    } catch (e) {
      throw Exception('Lỗi khi tải thống kê nhóm theo topic: $e');
    }
  }

  List<ResearchTopic> _topicsMatchingQueryName(
    List<ResearchTopic> topics,
    String query,
  ) {
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 1)
        .toList();
    if (tokens.isEmpty) return topics;

    return topics.where((topic) {
      final name = topic.name.toLowerCase();
      return tokens.every(name.contains);
    }).toList();
  }

  /// Lấy thông tin chi tiết của một Journal theo ID
  Future<Journal> getJournalDetails(String journalId) async {
    final sourceId = _openAlexId(journalId);
    final Uri url = Uri.parse('${ApiConstants.baseUrl}/sources/$sourceId');

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
    List<String>? topicIds,
    int? year,
    int? minCitations,
    String? sortField,
    bool descending = true,
  }) async {
    final sourceId = _openAlexId(journalId);
    String filter = 'primary_location.source.id:$sourceId';
    if (year != null) {
      filter += ',publication_year:$year';
    }
    if (minCitations != null && minCitations > 0) {
      filter += ',cited_by_count:>$minCitations';
    }
    final topicFilter = _topicFilterValue(topicIds: topicIds);
    if (topicFilter != null && topicFilter.isNotEmpty) {
      filter += ',primary_topic.id:$topicFilter';
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
      'select': _workSelectFields,
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
  Future<List<TrendData>> getJournalYearlyTrend(
    String journalId, {
    List<String>? topicIds,
  }) async {
    final sourceId = _openAlexId(journalId);
    String filter = 'primary_location.source.id:$sourceId';
    final topicFilter = _topicFilterValue(topicIds: topicIds);
    if (topicFilter != null && topicFilter.isNotEmpty) {
      filter += ',primary_topic.id:$topicFilter';
    }

    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {'filter': filter, 'group_by': 'publication_year'},
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
      final sourceId = _openAlexId(journalId);
      final topTopics = await getJournalTopTopics(journalId);
      Map<String, List<TrendData>> evolution = {};

      // Lấy dữ liệu cho top 3 topics
      for (var topic in topTopics.take(3)) {
        final name = topic['name'] as String;
        final id = topic['id'] as String;
        if (id.isEmpty) continue;

        final filterField =
            topic['filter_field'] as String? ?? 'primary_topic.id';
        final Uri url =
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
            ).replace(
              queryParameters: {
                'filter':
                    'primary_location.source.id:$sourceId,$filterField:$id',
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
    final sourceId = _openAlexId(journalId);
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': 'primary_location.source.id:$sourceId',
            'group_by': 'primary_topic.id',
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final topics = _mapTopicGroups(
        data['group_by'] ?? [],
        filterField: 'primary_topic.id',
      );
      if (topics.isNotEmpty) return topics;

      final fallbackUrl =
          Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
          ).replace(
            queryParameters: {
              'filter': 'primary_location.source.id:$sourceId',
              'group_by': 'concepts.id',
            },
          );
      final fallbackData = await _getWithRetryAndCache(fallbackUrl);
      return _mapTopicGroups(
        fallbackData['group_by'] ?? [],
        filterField: 'concepts.id',
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getJournalTopAuthors(
    String journalId, {
    List<String>? topicIds,
    int perPage = 8,
  }) async {
    return _getJournalGroupedCounts(
      journalId,
      'authorships.author.id',
      topicIds: topicIds,
      perPage: perPage,
    );
  }

  Future<List<Map<String, dynamic>>> _getJournalGroupedCounts(
    String journalId,
    String groupBy, {
    List<String>? topicIds,
    int perPage = 8,
  }) async {
    final sourceId = _openAlexId(journalId);
    String filter = 'primary_location.source.id:$sourceId';
    final topicFilter = _topicFilterValue(topicIds: topicIds);
    if (topicFilter != null && topicFilter.isNotEmpty) {
      filter += ',primary_topic.id:$topicFilter';
    }

    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': filter,
            'group_by': groupBy,
            'per_page': perPage.toString(),
          },
        );

    try {
      final data = await _getWithRetryAndCache(url);
      final List groups = data['group_by'] ?? [];
      return groups
          .where((group) {
            final name = group['key_display_name']?.toString() ?? '';
            return name.isNotEmpty && name.toLowerCase() != 'unknown';
          })
          .map(
            (group) => {
              'id': group['key']?.toString() ?? '',
              'name': group['key_display_name']?.toString() ?? '',
              'count': (group['count'] as num?)?.toInt() ?? 0,
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<Map<String, dynamic>> _mapTopicGroups(
    List groups, {
    required String filterField,
  }) {
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
            'filter_field': filterField,
          },
        )
        .toList();
  }

  /// Tìm kiếm bài báo theo ID tác giả có hỗ trợ phân trang
  Future<Map<String, dynamic>> getWorksByAuthor(
    String authorId, {
    int page = 1,
    int perPage = 10,
  }) async {
    final normalizedAuthorId = _openAlexId(authorId);
    final Uri url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.worksEndpoint}',
        ).replace(
          queryParameters: {
            'filter': 'author.id:$normalizedAuthorId',
            'sort': 'cited_by_count:desc',
            'page': page.toString(),
            'per_page': perPage.toString(),
            'select': _workSelectFields,
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
}
