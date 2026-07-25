import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'dashboard_view_model.dart';

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
      title: 'Dashboard Overview',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.summary == null) {
            return const LoadingView();
          }

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
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildMetricsGrid(context, summary),
                const SizedBox(height: 48),
                _buildQuickActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chào mừng trở lại, Admin',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dưới đây là tóm tắt dữ liệu hệ thống tính đến hôm nay.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, dynamic summary) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final isTablet = MediaQuery.of(context).size.width > 800;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 1),
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      childAspectRatio: 2.1,
      children: [
        _MetricTile(
          label: 'Tổng người dùng',
          value: summary.userCount.toString(),
          icon: Icons.people,
          color: const Color(0xFF6366F1),
          trend: '+12%',
          onTap: () => Navigator.of(context).pushNamed(AdminRoutes.users),
        ),
        _MetricTile(
          label: 'Số lượng tạp chí',
          value: summary.journalCount.toString(),
          icon: Icons.book,
          color: const Color(0xFFF59E0B),
          trend: '+5%',
          onTap: () => Navigator.of(context).pushNamed(AdminRoutes.firestoreCollections),
        ),
        _MetricTile(
          label: 'Tổng bài báo',
          value: summary.publicationCount.toString(),
          icon: Icons.article,
          color: const Color(0xFF10B981),
          trend: '+24%',
          onTap: () => Navigator.of(context).pushNamed(AdminRoutes.firestoreCollections),
        ),
        _MetricTile(
          label: 'Tệp lưu trữ',
          value: summary.storageFileCount.toString(),
          icon: Icons.cloud_done,
          color: const Color(0xFF8B5CF6),
          trend: '+8%',
          onTap: () => Navigator.of(context).pushNamed(AdminRoutes.storage),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Truy cập nhanh',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _QuickActionCard(
              label: 'Quản lý Users',
              icon: Icons.people_outline,
              route: AdminRoutes.users,
            ),
            _QuickActionCard(
              label: 'Dữ liệu Firestore',
              icon: Icons.dns,
              route: AdminRoutes.firestoreCollections,
            ),
            _QuickActionCard(
              label: 'Cloud Storage',
              icon: Icons.cloud_outlined,
              route: AdminRoutes.storage,
            ),
            _QuickActionCard(
              label: 'Gửi Thông báo',
              icon: Icons.notifications_active_outlined,
              route: AdminRoutes.messaging,
            ),
            _QuickActionCard(
              label: 'Lịch sử Audit',
              icon: Icons.history,
              route: AdminRoutes.auditLogs,
            ),
            _QuickActionCard(
              label: 'Cấu hình App',
              icon: Icons.settings_applications,
              route: AdminRoutes.appConfig,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatefulWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final VoidCallback? onTap;

  @override
  State<_MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends State<_MetricTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? widget.color.withOpacity(0.3) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? widget.color.withOpacity(0.08) : Colors.black.withOpacity(0.02),
                blurRadius: _isHovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '', // Keep layout consistency
                      style: TextStyle(fontSize: 0),
                    ),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          widget.value,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.trend,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(widget.route),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF6366F1).withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? const Color(0xFF6366F1).withOpacity(0.5) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 22,
                color: _isHovered ? const Color(0xFF6366F1) : const Color(0xFF475569),
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _isHovered ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
