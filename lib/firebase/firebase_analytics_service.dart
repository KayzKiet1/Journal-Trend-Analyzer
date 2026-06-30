import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

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

  Future<void> logViewPublication({
    required String publicationTitle,
    required int publicationYear,
  }) {
    return _logEvent('view_publication', {
      'publication_title': publicationTitle,
      'publication_year': publicationYear,
    });
  }

  Future<void> logViewJournal({required String journalName}) {
    return _logEvent('view_journal', {'journal_name': journalName});
  }

  Future<void> logViewKeyword({required String keyword}) {
    return _logEvent('view_keyword', {'keyword': keyword});
  }

  Future<void> logExportPdf({required String topic}) {
    return _logEvent('export_pdf', {'topic': topic});
  }

  Future<void> _logEvent(
    String name, [
    Map<String, Object?> parameters = const {},
  ]) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters.map(
          (key, value) => MapEntry(key, _sanitizeValue(value)),
        ),
      );
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
