import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'dashboard_view_model.dart';

/// Trang Dashboard chính của hệ thống quản trị.
/// Hiển thị tổng quan các chỉ số hệ thống và cung cấp các liên kết truy cập nhanh.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Khởi tạo ViewModel và tự động tải dữ liệu tóm tắt.
    _viewModel = DashboardViewModel()..loadSummary();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Tổng quan hệ thống',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          // Trạng thái đang tải dữ liệu lần đầu.
          if (_viewModel.isLoading && _viewModel.summary == null) {
            return const LoadingView();
          }

          // Trạng thái gặp lỗi khi tải dữ liệu.
          if (_viewModel.errorMessage != null && _viewModel.summary == null) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          final summary = _viewModel.summary;
          if (summary == null) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            onRefresh: _viewModel.loadSummary,
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                // Khối tiêu đề chào mừng.
                Text(
                  'Chào mừng quay trở lại, Admin',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dưới đây là các số liệu thống kê mới nhất về ứng dụng của bạn.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 32),

                // Lưới hiển thị các thẻ chỉ số (Metrics).
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _MetricTile(
                      label: 'Người dùng',
                      value: summary.userCount.toString(),
                      icon: Icons.people_alt_outlined,
                      color: Colors.blue,
                      onTap: () => Navigator.of(context).pushNamed(AdminRoutes.users),
                    ),
                    _MetricTile(
                      label: 'Tạp chí',
                      value: summary.journalCount.toString(),
                      icon: Icons.menu_book_outlined,
                      color: Colors.orange,
                      onTap: () => Navigator.of(context).pushNamed(AdminRoutes.firestoreCollections),
                    ),
                    _MetricTile(
                      label: 'Bài báo',
                      value: summary.publicationCount.toString(),
                      icon: Icons.article_outlined,
                      color: Colors.green,
                      onTap: () => Navigator.of(context).pushNamed(AdminRoutes.firestoreCollections),
                    ),
                    _MetricTile(
                      label: 'Tệp lưu trữ',
                      value: summary.storageFileCount.toString(),
                      icon: Icons.folder_outlined,
                      color: Colors.purple,
                      onTap: () => Navigator.of(context).pushNamed(AdminRoutes.storage),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Phân đoạn các liên kết nhanh (Quick Actions).
                Text(
                  'Truy cập nhanh',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _QuickLink(
                      label: 'Quản lý Người dùng',
                      routeName: AdminRoutes.users,
                      icon: Icons.people_alt_outlined,
                    ),
                    _QuickLink(
                      label: 'Dữ liệu Firestore',
                      routeName: AdminRoutes.firestoreCollections,
                      icon: Icons.storage_outlined,
                    ),
                    _QuickLink(
                      label: 'Cấu hình Hệ thống',
                      routeName: AdminRoutes.appConfig,
                      icon: Icons.tune_outlined,
                    ),
                    _QuickLink(
                      label: 'Quản lý Tệp tin',
                      routeName: AdminRoutes.storage,
                      icon: Icons.cloud_circle_outlined,
                    ),
                    _QuickLink(
                      label: 'Phân tích (Analytics)',
                      routeName: AdminRoutes.analytics,
                      icon: Icons.analytics_outlined,
                    ),
                    _QuickLink(
                      label: 'Gửi Thông báo',
                      routeName: AdminRoutes.messaging,
                      icon: Icons.notifications_outlined,
                    ),
                    _QuickLink(
                      label: 'Nhật ký Hoạt động',
                      routeName: AdminRoutes.auditLogs,
                      icon: Icons.history_outlined,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Widget thẻ hiển thị một chỉ số thống kê với hiệu ứng Hover.
class _MetricTile extends StatefulWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends State<_MetricTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 260,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? widget.color : colorScheme.outlineVariant,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered 
                  ? widget.color.withValues(alpha: 0.1) 
                  : theme.shadowColor.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 16 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon, 
                    color: widget.color, 
                    size: _isHovered ? 32 : 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.value,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget nút bấm truy cập nhanh vào các tính năng quản trị.
class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.label,
    required this.routeName,
    required this.icon,
  });

  final String label;
  final String routeName;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).pushNamed(routeName),
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
