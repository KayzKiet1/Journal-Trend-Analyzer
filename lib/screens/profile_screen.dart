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
    final message = userController.authError ?? 'Đăng nhập Google thành công!';
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
        content: Text('Đã đăng xuất khỏi Firebase.'),
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
          content: Text('Đã export và upload PDF report thành công.'),
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
          content: Text('Không thể tạo hoặc upload PDF report: $error'),
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
        content: Text('Đã copy report URL.'),
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
          content: Text('Không thể mở report URL.'),
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('USER INFORMATION', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.md),
            Consumer<UserController>(
              builder: (context, userController, _) {
                final isSignedIn = userController.isSignedIn;
                final photoUrl = userController.authPhotoUrl;
                final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

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
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: hasPhoto
                                ? NetworkImage(photoUrl)
                                : null,
                            child: hasPhoto
                                ? null
                                : const Icon(Icons.person_outline, size: 28),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSignedIn
                                      ? userController.authDisplayName
                                      : 'Chưa đăng nhập',
                                  style: AppTextStyles.h2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  isSignedIn
                                      ? userController.authEmail
                                      : 'Đăng nhập Google để đồng bộ tài khoản Firebase.',
                                  style: AppTextStyles.bodySmall,
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
                        'Firebase Authentication quản lý phiên đăng nhập Google. Email đăng nhập cũng được dùng làm email liên hệ khi gọi OpenAlex.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (isSignedIn) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: userController.isAuthLoading
                                ? null
                                : _signOut,
                            icon: const Icon(Icons.logout),
                            label: Text(
                              userController.isAuthLoading
                                  ? 'ĐANG XỬ LÝ...'
                                  : 'ĐĂNG XUẤT',
                            ),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: userController.isAuthLoading
                                ? null
                                : _signInWithGoogle,
                            icon: const Icon(Icons.login),
                            label: Text(
                              userController.isAuthLoading
                                  ? 'ĐANG ĐĂNG NHẬP...'
                                  : 'ĐĂNG NHẬP VỚI GOOGLE',
                            ),
                          ),
                        ),
                      ],
                      if (userController.authError != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          userController.authError!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
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
            Text('VỀ ỨNG DỤNG', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.md),
            _buildInfoCard(
              'Phiên bản',
              '1.0.0 (PRM393 Lab2)',
              Icons.info_outline,
            ),
            _buildInfoCard(
              'Nguồn dữ liệu',
              'OpenAlex API (Hệ thống dữ liệu học thuật mở)',
              Icons.cloud_outlined,
            ),
            _buildInfoCard(
              'Thiết kế',
              'Research Analytics Design System',
              Icons.palette_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportExport() {
    return Consumer2<PublicationController, UserController>(
      builder: (context, publicationController, userController, _) {
        final hasDashboardData =
            publicationController.currentTopicIds.isNotEmpty &&
            (publicationController.topicDashboardTotalWorks > 0 ||
                publicationController.topicDashboardTrends.isNotEmpty ||
                publicationController.topicDashboardPublications.isNotEmpty);
        final isSignedIn = userController.isSignedIn;
        final canExport = hasDashboardData && isSignedIn && !_isReportUploading;

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
                    child: Text('Research Trend PDF', style: AppTextStyles.h2),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Export current dashboard analytics as a PDF report and upload it to Firebase Storage.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildReportScope(publicationController),
              if (!isSignedIn) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildReportHint(
                  'Đăng nhập Google trước khi upload report lên Firebase Storage.',
                ),
              ],
              if (!hasDashboardData) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildReportHint(
                  'Search và chọn topic ở HOME trước để tạo dashboard report.',
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
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
                        ? 'ĐANG TẠO VÀ UPLOAD REPORT...'
                        : 'EXPORT PDF & UPLOAD',
                  ),
                ),
              ),
              if (_uploadedReportUrl != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text('FIREBASE STORAGE URL', style: AppTextStyles.labelCaps),
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
            '${controller.topicDashboardTotalWorks} publications loaded for export',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHint(String message) {
    return Text(
      message,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
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
                'Nhận thông báo về chủ đề nghiên cứu, citation alerts và cập nhật xu hướng từ Firebase.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildNotificationStatusRow(controller),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.isLoading
                      ? null
                      : controller.requestPermission,
                  icon: const Icon(Icons.notification_add_outlined),
                  label: Text(
                    controller.isLoading
                        ? 'ĐANG KIỂM TRA...'
                        : 'ENABLE NOTIFICATIONS',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('NOTIFICATION TOPICS', style: AppTextStyles.labelCaps),
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
      child: Row(
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
            'Chưa có thông báo nào từ Firebase Cloud Messaging.',
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
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: _firebaseDemoCardDecoration(),
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
                'Điều chỉnh giới hạn hiển thị journal, keyword và trạng thái export report từ Firebase Console mà không cần rebuild app.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Status: ${controller.remoteConfigStatus}',
                style: AppTextStyles.bodySmall,
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
                  onPressed: controller.isRemoteConfigLoading
                      ? null
                      : controller.fetchRemoteConfig,
                  icon: controller.isRemoteConfigLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_outlined),
                  label: Text(
                    controller.isRemoteConfigLoading
                        ? 'ĐANG TẢI CONFIG...'
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
                'Gửi handled exception hoặc tạo test crash có chủ đích để kiểm tra crash monitoring trên Firebase.',
                style: AppTextStyles.bodySmall,
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
                        ? 'ĐANG GỬI...'
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
            style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent),
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
          'App sẽ crash có chủ đích để gửi báo cáo lên Firebase Crashlytics. Chỉ dùng khi demo.',
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
            // Thêm Expanded để tránh lỗi overflow khi text quá dài
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
                  maxLines: 2, // Cho phép hiển thị tối đa 2 dòng
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
