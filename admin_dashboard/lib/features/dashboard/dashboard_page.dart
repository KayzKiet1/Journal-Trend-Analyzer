import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/models/dashboard_summary.dart';
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
      title: 'Dashboard',
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
          if (summary == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: _viewModel.loadSummary,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _DashboardHeader(summary: summary),
                const SizedBox(height: 16),
                _MetricGrid(summary: summary),
                const SizedBox(height: 16),
                _DashboardCharts(summary: summary),
                const SizedBox(height: 16),
                const _QuickActions(),
                if (_viewModel.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _viewModel.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final generatedAt = summary.generatedAt?.toLocal().toString() ?? '-';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.dashboard_customize_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System overview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated $generatedAt',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Users',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AdminRoutes.users),
              icon: const Icon(Icons.people_alt_outlined),
            ),
            IconButton(
              tooltip: 'Storage',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AdminRoutes.storage),
              icon: const Icon(Icons.folder_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'Users',
        value: '${summary.userCount}',
        detail: '+${summary.newUsers7d} in 7d, +${summary.newUsers30d} in 30d',
        icon: Icons.people_alt_outlined,
        color: const Color(0xFF2563EB),
        route: AdminRoutes.users,
      ),
      _MetricData(
        label: 'Storage',
        value: _formatBytes(summary.storageTotalBytes),
        detail: '${summary.storageFileCount} files',
        icon: Icons.cloud_done_outlined,
        color: const Color(0xFF059669),
        route: AdminRoutes.storage,
      ),
      _MetricData(
        label: 'Analytics',
        value: '${summary.analyticsEvents7d}',
        detail: '${summary.activeUsers7d} active users in 7d',
        icon: Icons.analytics_outlined,
        color: const Color(0xFF7C3AED),
        route: AdminRoutes.analytics,
      ),
      _MetricData(
        label: 'System health',
        value: '${summary.recentSystemHealthCount}',
        detail: 'issues/events in 7d',
        icon: Icons.monitor_heart_outlined,
        color: const Color(0xFFDC2626),
        route: AdminRoutes.systemHealth,
      ),
      _MetricData(
        label: 'Journals',
        value: '${summary.journalCount}',
        detail: 'Firestore documents',
        icon: Icons.menu_book_outlined,
        color: const Color(0xFFD97706),
        route: AdminRoutes.firestoreCollections,
      ),
      _MetricData(
        label: 'Publications',
        value: '${summary.publicationCount}',
        detail: 'Firestore documents',
        icon: Icons.article_outlined,
        color: const Color(0xFF0F766E),
        route: AdminRoutes.firestoreCollections,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = width >= 1200
            ? (width - 36) / 4
            : width >= 820
            ? (width - 24) / 3
            : width >= 560
            ? (width - 12) / 2
            : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _MetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DashboardCharts extends StatelessWidget {
  const _DashboardCharts({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 1020;
        final charts = [
          _BarChartCard(
            title: 'Firestore collections',
            icon: Icons.table_chart_outlined,
            emptyText: 'No collection data.',
            data: summary.collectionCounts,
            route: AdminRoutes.firestoreCollections,
          ),
          _BarChartCard(
            title: 'Storage folders',
            icon: Icons.folder_copy_outlined,
            emptyText: 'No storage folder data.',
            data: summary.storageFolderCounts,
            route: AdminRoutes.storage,
          ),
        ];

        if (!twoColumns) {
          return Column(
            children: [charts.first, const SizedBox(height: 16), charts.last],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: charts.first),
            const SizedBox(width: 16),
            Expanded(child: charts.last),
          ],
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final String route;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(metric.route),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(metric.icon, color: metric.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(metric.label, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      metric.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
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

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({
    required this.title,
    required this.icon,
    required this.emptyText,
    required this.data,
    required this.route,
  });

  final String title;
  final IconData icon;
  final String emptyText;
  final Map<String, int> data;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final chartEntries = entries.take(8).toList();
    final maxValue = chartEntries.fold<int>(
      1,
      (max, entry) => entry.value > max ? entry.value : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(route),
                  child: const Text('View'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (chartEntries.isEmpty)
              Text(
                emptyText,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              )
            else
              ...chartEntries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 136,
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: entry.value / maxValue,
                            minHeight: 12,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${entry.value}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = const [
      _QuickAction('Users', Icons.people_outline, AdminRoutes.users),
      _QuickAction(
        'Firestore',
        Icons.storage_outlined,
        AdminRoutes.firestoreCollections,
      ),
      _QuickAction('Storage', Icons.folder_outlined, AdminRoutes.storage),
      _QuickAction(
        'Messaging',
        Icons.notifications_outlined,
        AdminRoutes.messaging,
      ),
      _QuickAction(
        'Notifications',
        Icons.mark_email_read_outlined,
        AdminRoutes.notificationHistory,
      ),
      _QuickAction('Audit Logs', Icons.history_outlined, AdminRoutes.auditLogs),
      _QuickAction('App Config', Icons.tune_outlined, AdminRoutes.appConfig),
      _QuickAction(
        'System Health',
        Icons.monitor_heart_outlined,
        AdminRoutes.systemHealth,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions
              .map(
                (action) => OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(action.route),
                  icon: Icon(action.icon),
                  label: Text(action.label),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}
