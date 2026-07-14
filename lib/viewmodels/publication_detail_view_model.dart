import 'package:flutter/foundation.dart';

import '../firebase/firebase_analytics_service.dart';
import '../models/publication_model.dart';

class PublicationDetailViewModel extends ChangeNotifier {
  PublicationDetailViewModel({FirebaseAnalyticsService? analyticsService})
    : _analyticsService = analyticsService ?? FirebaseAnalyticsService();

  final FirebaseAnalyticsService _analyticsService;

  Future<void> logViewPublication(Publication publication) async {
    await _analyticsService.logViewPublication(
      publicationTitle: publication.title,
      publicationYear: publication.publicationYear,
    );
  }
}
