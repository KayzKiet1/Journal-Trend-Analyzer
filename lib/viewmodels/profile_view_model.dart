import 'package:flutter/foundation.dart';

import '../firebase/firebase_analytics_service.dart';
import '../firebase/firebase_storage_service.dart';
import '../services/dashboard_report_service.dart';
import 'keywords_view_model.dart';
import 'publication_view_model.dart';
import 'user_view_model.dart';

class ProfileActionResult {
  final bool isSuccess;
  final String message;

  const ProfileActionResult({required this.isSuccess, required this.message});
}

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    FirebaseAnalyticsService? analyticsService,
    DashboardReportService? reportService,
    FirebaseStorageService? storageService,
  }) : _analyticsService = analyticsService ?? FirebaseAnalyticsService(),
       _reportService = reportService ?? DashboardReportService(),
       _storageService = storageService ?? FirebaseStorageService();

  final FirebaseAnalyticsService _analyticsService;
  final DashboardReportService _reportService;
  final FirebaseStorageService _storageService;

  bool _isReportUploading = false;
  String? _uploadedReportUrl;

  bool get isReportUploading => _isReportUploading;
  String? get uploadedReportUrl => _uploadedReportUrl;

  Future<ProfileActionResult> signInWithGoogle(
    UserViewModel userController,
  ) async {
    await userController.signInWithGoogle();
    if (userController.authError == null) {
      await _analyticsService.logLogin();
      return const ProfileActionResult(
        isSuccess: true,
        message: 'Signed in with Google.',
      );
    }

    return ProfileActionResult(
      isSuccess: false,
      message: userController.authError!,
    );
  }

  Future<ProfileActionResult> signOut(UserViewModel userController) async {
    await userController.signOut();
    if (userController.authError == null) {
      await _analyticsService.logLogout();
      return const ProfileActionResult(
        isSuccess: true,
        message: 'Signed out from Firebase.',
      );
    }

    return ProfileActionResult(
      isSuccess: false,
      message: userController.authError!,
    );
  }

  Future<ProfileActionResult> exportAndUploadReport({
    required PublicationViewModel publicationController,
    required KeywordsViewModel keywordsController,
    required UserViewModel userController,
  }) async {
    final firebaseUser = userController.firebaseUser;
    if (firebaseUser == null) {
      return const ProfileActionResult(
        isSuccess: false,
        message: 'Please sign in before exporting a report.',
      );
    }

    final topic = publicationController.currentTopic;
    _isReportUploading = true;
    notifyListeners();

    try {
      final pdfBytes = await _reportService.buildResearchTrendReport(
        topic: topic,
        exportedBy: userController.authEmail,
        totalPublications: publicationController.topicDashboardTotalWorks,
        averageCitations: publicationController.topicDashboardAverageCitations,
        peakYear: publicationController.topicDashboardPeakYear,
        topAuthors: publicationController.topicDashboardTopAuthors,
        topJournals: publicationController.topicDashboardTopJournals,
        publicationTrends: publicationController.topicDashboardTrends,
        influentialPublications:
            publicationController.topicDashboardPublications,
        topKeywords: keywordsController.topKeywords,
        keywordGrowth: keywordsController.keywordGrowth,
      );

      final fileName =
          'research_trend_${_safeFileSegment(topic)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final downloadUrl = await _storageService.uploadPdfReport(
        bytes: pdfBytes,
        fileName: fileName,
        userId: firebaseUser.uid,
      );

      await _analyticsService.logExportPdf(topic: topic);
      _uploadedReportUrl = downloadUrl;
      return const ProfileActionResult(
        isSuccess: true,
        message: 'PDF report exported and uploaded.',
      );
    } on StorageUploadException catch (error) {
      return ProfileActionResult(isSuccess: false, message: error.message);
    } catch (error) {
      return ProfileActionResult(
        isSuccess: false,
        message: 'Could not create or upload PDF report: $error',
      );
    } finally {
      _isReportUploading = false;
      notifyListeners();
    }
  }

  String _safeFileSegment(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (normalized.isEmpty) return 'research_topic';
    return normalized.length > 40 ? normalized.substring(0, 40) : normalized;
  }
}
