import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/firebase_demo_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/publication_controller.dart';
import '../firebase/firebase_analytics_service.dart';
import '../firebase/firebase_storage_service.dart';
import '../models/app_notification_model.dart';
import '../services/dashboard_report_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAnalyticsService _analyticsService = FirebaseAnalyticsService();
  final DashboardReportService _reportService = DashboardReportService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  bool _isReportUploading = false;
  String? _uploadedReportUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationController>().initialize();
      }
    });
  }

  Future<void> _signInWithGoogle() async {
    final userController = context.read<UserController>();
    await userController.signInWithGoogle();

    if (!mounted) return;
    if (userController.authError == null) {
      _analyticsService.logLogin();
    }
    final message = userController.authError ?? 'Signed in with Google.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: userController.authError == null
            ? AppColors.success
            : AppColors.error,
      ),
    );
  }

  Future<void> _signOut() async {
    final userController = context.read<UserController>();
    await userController.signOut();

    if (!mounted) return;
    if (userController.authError == null) {
      _analyticsService.logLogout();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signed out from Firebase.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _exportAndUploadReport(
    PublicationController publicationController,
    UserController userController,
  ) async {
    final firebaseUser = userController.firebaseUser;
    if (firebaseUser == null) return;

    final topic = publicationController.currentTopic;
    setState(() => _isReportUploading = true);

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
      );

      final fileName =
          'research_trend_${_safeFileSegment(topic)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final downloadUrl = await _storageService.uploadPdfReport(
        bytes: pdfBytes,
        fileName: fileName,
        userId: firebaseUser.uid,
      );

      _analyticsService.logExportPdf(topic: topic);

      if (!mounted) return;
      setState(() => _uploadedReportUrl = downloadUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF report exported and uploaded.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on StorageUploadException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create or upload PDF report: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isReportUploading = false);
      }
    }
  }

  Future<void> _copyUploadedReportUrl() async {
    final url = _uploadedReportUrl;
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
    final url = _uploadedReportUrl;
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

  String _safeFileSegment(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (normalized.isEmpty) return 'research_topic';
    return normalized.length > 40 ? normalized.substring(0, 40) : normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        key: const Key('profile_content'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<UserController>(
              builder: (context, userController, _) =>
                  _buildProfileHero(userController),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFirebaseStatusOverview(),
            const SizedBox(height: AppSpacing.xl),
            Text('NOTIFICATION CENTER', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.md),
            _buildNotificationCenter(),
            const SizedBox(height: AppSpacing.xl),
            Text('REPORT EXPORT', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.md),
            _buildReportExport(),
            const SizedBox(height: AppSpacing.xl),
            Text('REMOTE CONFIG', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.md),
            _buildRemoteConfigDemo(),
            const SizedBox(height: AppSpacing.xl),
            Text('CRASHLYTICS DEMO', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.md),
            _buildCrashlyticsDemo(),
            const SizedBox(height: AppSpacing.xl),
            Text('ABOUT APP', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.md),
            _buildInfoCard(
              'Version',
              '1.0.0 (PRM393 Lab 03)',
              Icons.info_outline,
            ),
            _buildInfoCard('Data source', 'OpenAlex API', Icons.cloud_outlined),
            _buildInfoCard(
              'Design',
              'Research Analytics Design System',
              Icons.palette_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHero(UserController userController) {
    final isSignedIn = userController.isSignedIn;
    final photoUrl = userController.authPhotoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                child: hasPhoto
                    ? null
                    : const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSignedIn
                          ? userController.authDisplayName
                          : 'Guest researcher',
                      style: AppTextStyles.h1.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isSignedIn
                          ? userController.authEmail
                          : 'Sign in to export reports and sync Firebase demos.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Firebase Authentication manages Google sign-in, while this tab shows Messaging, Storage, Remote Config, and Crashlytics readiness in one place.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: isSignedIn
                ? OutlinedButton.icon(
                    key: const Key('sign_out_button'),
                    onPressed: userController.isAuthLoading ? null : _signOut,
                    icon: const Icon(Icons.logout),
                    label: Text(
                      userController.isAuthLoading
                          ? 'PROCESSING...'
                          : 'SIGN OUT',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    key: const Key('google_sign_in_button'),
                    onPressed: userController.isAuthLoading
                        ? null
                        : _signInWithGoogle,
                    icon: const Icon(Icons.login),
                    label: Text(
                      userController.isAuthLoading
                          ? 'SIGNING IN...'
                          : 'SIGN IN WITH GOOGLE',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
          ),
          if (userController.authError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              userController.authError!,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFirebaseStatusOverview() {
    return Consumer4<
      UserController,
      NotificationController,
      FirebaseDemoController,
      PublicationController
    >(
      builder:
          (
            context,
            userController,
            notificationController,
            firebaseDemoController,
            publicationController,
            _,
          ) {
            final hasDashboardData =
                publicationController.currentTopicIds.isNotEmpty &&
                (publicationController.topicDashboardTotalWorks > 0 ||
                    publicationController.topicDashboardTrends.isNotEmpty ||
                    publicationController
                        .topicDashboardPublications
                        .isNotEmpty);
            final exportEnabled =
                firebaseDemoController.remoteConfigValues.enableReportExport;
            final items = [
              _FirebaseStatusItem(
                icon: Icons.verified_user_outlined,
                label: 'Auth',
                value: userController.isSignedIn ? 'Signed in' : 'Guest',
                isReady: userController.isSignedIn,
              ),
              _FirebaseStatusItem(
                icon: Icons.notifications_active_outlined,
                label: 'FCM',
                value: notificationController.permissionStatus,
                isReady: notificationController.hasToken,
              ),
              _FirebaseStatusItem(
                icon: Icons.cloud_upload_outlined,
                label: 'Storage',
                value: hasDashboardData && userController.isSignedIn
                    ? 'Ready'
                    : 'Needs setup',
                isReady: hasDashboardData && userController.isSignedIn,
              ),
              _FirebaseStatusItem(
                icon: Icons.tune_outlined,
                label: 'Config',
                value: exportEnabled ? 'Export on' : 'Export off',
                isReady: exportEnabled,
              ),
            ];

            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: items.map(_buildFirebaseStatusTile).toList(),
            );
          },
    );
  }

  Widget _buildFirebaseStatusTile(_FirebaseStatusItem item) {
    final statusColor = item.isReady ? AppColors.success : AppColors.secondary;

    return SizedBox(
      width: MediaQuery.of(context).size.width >= 420
          ? (MediaQuery.of(context).size.width -
                    AppSpacing.lg * 2 -
                    AppSpacing.sm) /
                2
          : double.infinity,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: _firebaseDemoCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(item.icon, color: statusColor, size: 19),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: AppTextStyles.labelCaps),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportExport() {
    return Consumer3<
      PublicationController,
      UserController,
      FirebaseDemoController
    >(
      builder:
          (
            context,
            publicationController,
            userController,
            firebaseDemoController,
            _,
          ) {
            final hasDashboardData =
                publicationController.currentTopicIds.isNotEmpty &&
                (publicationController.topicDashboardTotalWorks > 0 ||
                    publicationController.topicDashboardTrends.isNotEmpty ||
                    publicationController
                        .topicDashboardPublications
                        .isNotEmpty);
            final isSignedIn = userController.isSignedIn;
            final exportEnabled =
                firebaseDemoController.remoteConfigValues.enableReportExport;
            final canExport =
                hasDashboardData &&
                isSignedIn &&
                exportEnabled &&
                !_isReportUploading;

            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.secondary, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Research Trend PDF',
                          style: AppTextStyles.h2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Generate a structured PDF from the current HOME topic dashboard and upload it to Firebase Storage.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildReportScope(publicationController),
                  const SizedBox(height: AppSpacing.md),
                  _buildExportRequirement(
                    'Google sign-in',
                    isSignedIn,
                    isSignedIn
                        ? userController.authEmail
                        : 'Required for Storage',
                  ),
                  _buildExportRequirement(
                    'HOME dashboard data',
                    hasDashboardData,
                    hasDashboardData
                        ? '${publicationController.topicDashboardTotalWorks} publications'
                        : 'Search and select a topic first',
                  ),
                  _buildExportRequirement(
                    'Remote Config export flag',
                    exportEnabled,
                    exportEnabled ? 'Enabled' : 'Disabled',
                  ),
                  _buildExportRequirement('Export format', true, 'PDF report'),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('export_pdf_button'),
                      onPressed: canExport
                          ? () => _exportAndUploadReport(
                              publicationController,
                              userController,
                            )
                          : null,
                      icon: _isReportUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        _isReportUploading
                            ? 'GENERATING AND UPLOADING...'
                            : 'EXPORT PDF & UPLOAD',
                      ),
                    ),
                  ),
                  if (_uploadedReportUrl != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'FIREBASE STORAGE URL',
                      style: AppTextStyles.labelCaps,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(
                      _uploadedReportUrl!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _copyUploadedReportUrl,
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('COPY URL'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _openUploadedReportUrl,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('OPEN'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
    );
  }

  Widget _buildReportScope(PublicationController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current report scope', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.xs),
          Text(
            controller.currentTopic.isEmpty
                ? 'No research topic selected yet.'
                : controller.currentTopic,
            style: AppTextStyles.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${controller.topicDashboardTotalWorks} publications, ${controller.topicDashboardTrends.length} yearly trend points, ${controller.topicDashboardTopJournals.length} journals',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildExportRequirement(String label, bool isReady, String value) {
    final statusColor = isReady ? AppColors.success : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isReady ? Icons.check_circle_outline : Icons.info_outline,
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCenter() {
    return Consumer<NotificationController>(
      builder: (context, controller, _) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.secondary, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Firebase Cloud Messaging',
                      style: AppTextStyles.h2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Manage push notification permission and optional research alert subscriptions.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildNotificationStatusRow(controller),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.canRequestPermission
                      ? controller.requestPermission
                      : null,
                  icon: Icon(
                    controller.isNotificationReady
                        ? Icons.notifications_active_outlined
                        : Icons.notification_add_outlined,
                  ),
                  label: Text(
                    controller.isLoading
                        ? 'CHECKING...'
                        : controller.isNotificationReady
                        ? 'NOTIFICATIONS ENABLED'
                        : 'ENABLE NOTIFICATIONS',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('OPTIONAL ALERT TOPICS', style: AppTextStyles.labelCaps),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Use these switches to subscribe this device to Firebase Messaging demo topics.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...NotificationController.preferences.map(
                (preference) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: controller.subscribedTopics.contains(preference.topic),
                  onChanged: controller.isLoading
                      ? null
                      : (enabled) => controller.setTopicSubscription(
                          preference.topic,
                          enabled,
                        ),
                  title: Text(preference.label, style: AppTextStyles.bodySmall),
                  subtitle: Text(
                    preference.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  controller.errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'RECEIVED NOTIFICATIONS',
                      style: AppTextStyles.labelCaps,
                    ),
                  ),
                  if (controller.notifications.isNotEmpty)
                    TextButton(
                      onPressed: controller.clearNotifications,
                      child: const Text('CLEAR'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (controller.notifications.isEmpty)
                _buildNotificationEmptyState()
              else
                ...controller.notifications.map(_buildNotificationItem),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationStatusRow(NotificationController controller) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Permission: ${controller.permissionStatus}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Device token: ${controller.compactToken()}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: controller.hasToken
                        ? AppColors.primary
                        : AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationEmptyState() {
    const examples = [
      'Trending research topic',
      'High citation alert',
      'Research trend update',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No Firebase Cloud Messaging notifications yet.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...examples.map(
            (example) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(example, style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                notification.type,
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.accent,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          if (notification.body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(notification.body, style: AppTextStyles.bodySmall),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatNotificationTime(notification.receivedAt),
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.secondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNotificationTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRemoteConfigDemo() {
    return Consumer<FirebaseDemoController>(
      builder: (context, controller, _) {
        final values = controller.remoteConfigValues;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_outlined, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Firebase Remote Config',
                      style: AppTextStyles.h2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Fetch display limits and the report-export flag from Firebase Console without rebuilding the app.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildConfigRow(
                      'Max journals displayed',
                      values.maxJournalsDisplay.toString(),
                      Icons.book_outlined,
                    ),
                    _buildConfigRow(
                      'Max keywords displayed',
                      values.maxKeywordsDisplay.toString(),
                      Icons.analytics_outlined,
                    ),
                    _buildConfigRow(
                      'Report export enabled',
                      values.enableReportExport ? 'true' : 'false',
                      Icons.picture_as_pdf_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Status: ${controller.remoteConfigStatus}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              if (controller.remoteConfigError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  controller.remoteConfigError!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('fetch_remote_config_button'),
                  onPressed: controller.isRemoteConfigLoading
                      ? null
                      : controller.fetchRemoteConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textInverted,
                    disabledBackgroundColor: AppColors.accent.withValues(
                      alpha: 0.65,
                    ),
                    disabledForegroundColor: AppColors.textInverted,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  icon: controller.isRemoteConfigLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textInverted,
                          ),
                        )
                      : const Icon(Icons.cloud_download_outlined),
                  label: Text(
                    controller.isRemoteConfigLoading
                        ? 'FETCHING CONFIG...'
                        : 'FETCH CONFIG',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCrashlyticsDemo() {
    return Consumer<FirebaseDemoController>(
      builder: (context, controller, _) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: _firebaseDemoCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bug_report_outlined,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Firebase Crashlytics',
                      style: AppTextStyles.h2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Record a handled exception or trigger a deliberate test crash for Firebase Crashlytics validation.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Test crash intentionally closes the app. Use it only while demoing Crashlytics.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.crashlyticsMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  controller.crashlyticsMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.isCrashlyticsLoading
                      ? null
                      : controller.recordHandledException,
                  icon: controller.isCrashlyticsLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.report_gmailerrorred_outlined),
                  label: Text(
                    controller.isCrashlyticsLoading
                        ? 'SENDING...'
                        : 'RECORD HANDLED EXCEPTION',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmTestCrash(controller),
                  icon: const Icon(Icons.warning_amber_outlined),
                  label: const Text('TRIGGER TEST CRASH'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfigRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title, style: AppTextStyles.bodySmall)),
          Text(
            value,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmTestCrash(FirebaseDemoController controller) async {
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

  BoxDecoration _firebaseDemoCardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(color: AppColors.secondary, width: 1.0),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FirebaseStatusItem {
  const _FirebaseStatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isReady,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isReady;
}
