import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:journal_trend_analyzer/models/publication_model.dart';
import 'package:journal_trend_analyzer/utils/api_constants.dart';

class OpenAlexException implements Exception {
  const OpenAlexException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenAlexService {
  OpenAlexService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Publication>> searchPublications(String topic) async {
    final trimmedTopic = topic.trim();
    if (trimmedTopic.isEmpty) {
      throw const OpenAlexException('Search topic cannot be empty.');
    }

    final uri = Uri.parse(ApiConstants.worksEndpoint).replace(
      queryParameters: {
        'search': trimmedTopic,
        'sort': 'cited_by_count:desc',
        'per_page': ApiConstants.defaultPerPage.toString(),
      },
    );

    try {
      final response = await _client
          .get(uri)
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode != HttpStatus.ok) {
        throw OpenAlexException(
          'OpenAlex request failed with status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const OpenAlexException('Unexpected response format from OpenAlex.');
      }

      final results = decoded['results'];
      if (results is! List) {
        return [];
      }

      return results
          .whereType<Map<String, dynamic>>()
          .map(Publication.fromOpenAlexJson)
          .toList();
    } on TimeoutException {
      throw const OpenAlexException(
        'Request timed out. Please check your connection and try again.',
      );
    } on FormatException {
      throw const OpenAlexException('Failed to parse OpenAlex response.');
    } on SocketException {
      throw const OpenAlexException(
        'Unable to reach OpenAlex. Please check your internet connection.',
      );
    } on OpenAlexException {
      rethrow;
    } catch (error) {
      throw OpenAlexException('An unexpected error occurred: $error');
    }
  }

  void dispose() {
    _client.close();
  }
}
