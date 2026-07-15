import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/journal_model.dart';
import '../../models/publication_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../viewmodels/firebase_view_model.dart';
import '../../viewmodels/journal_library_view_model.dart';
import '../../viewmodels/keywords_view_model.dart';
import '../../viewmodels/notification_view_model.dart';
import '../../viewmodels/publication_bookmark_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../viewmodels/publication_view_model.dart';
import '../../viewmodels/user_view_model.dart';
import '../journals/journal_detail_screen.dart';
import '../publications/publication_detail_screen.dart';
import 'widgets/auth/profile_hero.dart';
import 'widgets/bookmarks/saved_bookmarks_panel.dart';
import 'widgets/common/profile_info_card.dart';
import 'widgets/firebase/crashlytics_panel.dart';
import 'widgets/firebase/firebase_status_overview.dart';
import 'widgets/firebase/remote_config_panel.dart';
import 'widgets/notifications/notification_center_panel.dart';
import 'widgets/report/report_export_panel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationViewModel>().initialize();
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final userController = context.read<UserViewModel>();
    final result = await _viewModel.signInWithGoogle(userController);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _signOut() async {
    final userController = context.read<UserViewModel>();
    final result = await _viewModel.signOut(userController);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _exportAndUploadReport(
    PublicationViewModel publicationController,
    KeywordsViewModel keywordsController,
    UserViewModel userController,
  ) async {
    final result = await _viewModel.exportAndUploadReport(
      publicationController: publicationController,
      keywordsController: keywordsController,
      userController: userController,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _copyUploadedReportUrl() async {
    final url = _viewModel.uploadedReportUrl;
    if (url == null || url.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report URL copied.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _openUploadedReportUrl() async {
    final url = _viewModel.uploadedReportUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open report URL.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openBookmarkedPublication(Publication publication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublicationDetailScreen(publication: publication),
      ),
    );
  }

  void _openBookmarkedJournal(Journal journal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalDetailScreen(
          journalId: journal.id,
          journalName: journal.name,
          journalForTesting: journal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body:
          Consumer4<
            UserViewModel,
            NotificationViewModel,
            FirebaseViewModel,
            PublicationViewModel
          >(
            builder:
                (
                  context,
                  userController,
                  notificationController,
                  firebaseController,
                  publicationController,
                  _,
                ) {
                  final remoteConfig = firebaseController.remoteConfigValues;
                  final keywordsController = context.watch<KeywordsViewModel>();
                  final journalLibrary = context
                      .watch<JournalLibraryViewModel>();
                  final publicationBookmarks = context
                      .watch<PublicationBookmarkViewModel>();
                  final hasDashboardData =
                      publicationController.topicDashboardTotalWorks > 0 ||
                      publicationController
                          .topicDashboardPublications
                          .isNotEmpty ||
                      publicationController.topicDashboardTrends.isNotEmpty ||
                      keywordsController.topKeywords.isNotEmpty ||
                      keywordsController.keywordGrowth.isNotEmpty;
                  final statusItems = [
                    FirebaseStatusItem(
                      icon: Icons.login_outlined,
                      label: 'Auth',
                      value: userController.isSignedIn ? 'Signed in' : 'Guest',
                      isReady: userController.isSignedIn,
                    ),
                    FirebaseStatusItem(
                      icon: Icons.notifications_outlined,
                      label: 'Messaging',
                      value: notificationController.permissionStatus,
                      isReady: notificationController.isNotificationReady,
                    ),
                    FirebaseStatusItem(
                      icon: Icons.tune_outlined,
                      label: 'Remote Config',
                      value: firebaseController.remoteConfigStatus,
                      isReady: firebaseController.remoteConfigError == null,
                    ),
                    FirebaseStatusItem(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'Storage',
                      value: _viewModel.uploadedReportUrl == null
                          ? 'No report'
                          : 'Report uploaded',
                      isReady: _viewModel.uploadedReportUrl != null,
                    ),
                  ];
                  return SingleChildScrollView(
                    key: const Key('profile_content'),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileHero(
                          isSignedIn: userController.isSignedIn,
                          photoUrl: userController.authPhotoUrl,
                          displayName: userController.authDisplayName,
                          email: userController.authEmail,
                          isAuthLoading: userController.isAuthLoading,
                          authError: userController.authError,
                          onSignIn: _signInWithGoogle,
                          onSignOut: _signOut,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FirebaseStatusOverview(items: statusItems),
                        const SizedBox(height: AppSpacing.xl),
                        Text('SAVED BOOKMARKS', style: AppTextStyles.labelCaps),
                        const SizedBox(height: AppSpacing.md),
                        SavedBookmarksPanel(
                          publications: publicationBookmarks.bookmarks,
                          journals: journalLibrary.favorites,
                          onOpenPublication: _openBookmarkedPublication,
                          onRemovePublication:
                              publicationBookmarks.toggleBookmark,
                          onOpenJournal: _openBookmarkedJournal,
                          onRemoveJournal: journalLibrary.toggleFavorite,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'NOTIFICATION CENTER',
                          style: AppTextStyles.labelCaps,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        NotificationCenterPanel(
                          permissionStatus:
                              notificationController.permissionStatus,
                          compactToken: notificationController.compactToken(),
                          hasToken: notificationController.hasToken,
                          isNotificationReady:
                              notificationController.isNotificationReady,
                          wantsNotifications:
                              notificationController.wantsNotifications,
                          isLoading: notificationController.isLoading,
                          errorMessage: notificationController.errorMessage,
                          notifications: notificationController.notifications,
                          onNotificationsEnabledChanged:
                              notificationController.setNotificationsEnabled,
                          onClearNotifications:
                              notificationController.clearNotifications,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text('REPORT EXPORT', style: AppTextStyles.labelCaps),
                        const SizedBox(height: AppSpacing.md),
                        AnimatedBuilder(
                          animation: _viewModel,
                          builder: (context, _) => ReportExportPanel(
                            isUploading: _viewModel.isReportUploading,
                            uploadedReportUrl: _viewModel.uploadedReportUrl,
                            currentTopic: publicationController.currentTopic,
                            totalPublications:
                                publicationController.topicDashboardTotalWorks,
                            trendPointCount: publicationController
                                .topicDashboardTrends
                                .length,
                            journalCount: publicationController
                                .topicDashboardTopJournals
                                .length,
                            keywordCount: keywordsController.topKeywords.length,
                            keywordGrowthCount:
                                keywordsController.keywordGrowth.length,
                            hasDashboardData: hasDashboardData,
                            isSignedIn: userController.isSignedIn,
                            authEmail: userController.authEmail,
                            exportEnabled: remoteConfig.enableReportExport,
                            onExport: () => _exportAndUploadReport(
                              publicationController,
                              keywordsController,
                              userController,
                            ),
                            onCopyUrl: _copyUploadedReportUrl,
                            onOpenUrl: _openUploadedReportUrl,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text('REMOTE CONFIG', style: AppTextStyles.labelCaps),
                        const SizedBox(height: AppSpacing.md),
                        RemoteConfigPanel(
                          maxJournalsDisplay: remoteConfig.maxJournalsDisplay,
                          maxKeywordsDisplay: remoteConfig.maxKeywordsDisplay,
                          enableReportExport: remoteConfig.enableReportExport,
                          status: firebaseController.remoteConfigStatus,
                          error: firebaseController.remoteConfigError,
                          isLoading: firebaseController.isRemoteConfigLoading,
                          onFetch: firebaseController.fetchRemoteConfig,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'CRASHLYTICS DEMO',
                          style: AppTextStyles.labelCaps,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CrashlyticsPanel(
                          isLoading: firebaseController.isCrashlyticsLoading,
                          message: firebaseController.crashlyticsMessage,
                          onRecordHandledException:
                              firebaseController.recordHandledException,
                          onConfirmTestCrash: () =>
                              _confirmTestCrash(firebaseController),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text('ABOUT APP', style: AppTextStyles.labelCaps),
                        const SizedBox(height: AppSpacing.md),
                        const ProfileInfoCard(
                          title: 'Version',
                          value: '1.0.0 (PRM393 Lab 03)',
                          icon: Icons.info_outline,
                        ),
                        const ProfileInfoCard(
                          title: 'Data source',
                          value: 'OpenAlex API',
                          icon: Icons.cloud_outlined,
                        ),
                        const ProfileInfoCard(
                          title: 'Design',
                          value: 'Research Analytics Design System',
                          icon: Icons.palette_outlined,
                        ),
                      ],
                    ),
                  );
                },
          ),
    );
  }

  Future<void> _confirmTestCrash(FirebaseViewModel controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trigger test crash?'),
        content: const Text(
          'The app will intentionally crash to send a Firebase Crashlytics report. Use this only during demo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CRASH APP'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.triggerTestCrash();
    }
  }
}
