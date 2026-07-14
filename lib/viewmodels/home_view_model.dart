import 'package:flutter/foundation.dart';

import '../firebase/firebase_analytics_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({FirebaseAnalyticsService? analyticsService})
    : _analyticsService = analyticsService ?? FirebaseAnalyticsService();

  final FirebaseAnalyticsService _analyticsService;

  Future<void> logSearchTopic({
    required String keyword,
    required int topicCount,
  }) async {
    await _analyticsService.logSearchTopic(
      keyword: keyword,
      topicCount: topicCount,
    );
  }
}
