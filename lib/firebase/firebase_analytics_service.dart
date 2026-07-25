import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_event_service.dart';

class FirebaseAnalyticsService {
  FirebaseAnalyticsService({
    FirebaseAnalytics? analytics,
    AnalyticsEventService? eventService,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance,
       _eventService = eventService ?? AnalyticsEventService();

  final FirebaseAnalytics _analytics;
  final AnalyticsEventService _eventService;

  Future<void> logLogin({String method = 'google'}) {
    return _logEvent('login', {'method': method});
  }

  Future<void> logLogout() {
    return _logEvent('logout');
  }

  Future<void> logSearchTopic({required String keyword, int topicCount = 1}) {
    return _logEvent('search_topic', {
      'keyword': keyword,
      'topic_count': topicCount,
    });
  }

  Future<void> logSearchJournal({required String query, int resultCount = 0}) {
    return _logEvent('search_journal', {
      'query': query,
      'result_count': resultCount,
    });
  }

  Future<void> logViewPublication({
    String publicationId = '',
    required String publicationTitle,
    required int publicationYear,
    String journalId = '',
    String journalName = '',
  }) {
    return _logEvent('view_publication', {
      'publication_id': publicationId,
      'publication_title': publicationTitle,
      'publication_year': publicationYear,
      'journal_id': journalId,
      'journal_name': journalName,
    });
  }

  Future<void> logViewJournal({
    String journalId = '',
    required String journalName,
  }) {
    return _logEvent('view_journal', {
      'journal_id': journalId,
      'journal_name': journalName,
    });
  }

  Future<void> logViewKeyword({required String keyword}) {
    return _logEvent('view_keyword', {'keyword': keyword});
  }

  Future<void> logExportPdf({required String topic}) {
    return logExportReport(topic: topic);
  }

  Future<void> logExportReport({required String topic}) {
    return _logEvent('export_report', {'topic': topic});
  }

  Future<void> _logEvent(
    String name, [
    Map<String, Object?> parameters = const {},
  ]) async {
    try {
      final sanitizedParameters = parameters.map(
        (key, value) => MapEntry(key, _sanitizeValue(value)),
      );

      await Future.wait([
        _analytics.logEvent(name: name, parameters: sanitizedParameters),
        _eventService.logEvent(eventName: name, metadata: sanitizedParameters),
      ]);
    } catch (_) {
      // Analytics must never interrupt the user workflow.
    }
  }

  Object _sanitizeValue(Object? value) {
    if (value is num) return value;
    final text = value?.toString() ?? '';
    if (text.length <= 100) return text;
    return text.substring(0, 100);
  }
}
