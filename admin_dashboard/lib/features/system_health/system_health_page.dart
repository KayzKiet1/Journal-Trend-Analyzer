import 'package:flutter/material.dart';

import '../../data/models/system_health.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'system_health_view_model.dart';

class SystemHealthPage extends StatefulWidget {
  const SystemHealthPage({super.key});

  @override
  State<SystemHealthPage> createState() => _SystemHealthPageState();
}

class _SystemHealthPageState extends State<SystemHealthPage> {
  late final SystemHealthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SystemHealthViewModel()..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'System Health',
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
            onRefresh: _viewModel.load,
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                _HealthHeader(summary: summary, onRefresh: _viewModel.load),
                const SizedBox(height: 18),
                if (summary.items.isEmpty)
                  const _EmptyHealthState()
                else
                  ...summary.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HealthItemCard(item: item),
                    ),
                  ),
                if (_viewModel.errorMessage != null) ...[
                  const SizedBox(height: 12),
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

class _HealthHeader extends StatelessWidget {
  const _HealthHeader({required this.summary, required this.onRefresh});

  final SystemHealthSummary summary;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.monitor_heart, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${summary.openIssueCount} open issues',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nguồn: app_errors, function_errors, system_health',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHealthState extends StatelessWidget {
  const _EmptyHealthState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: colorScheme.primary,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có lỗi hệ thống được ghi nhận',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Khi mobile app hoặc Cloud Functions ghi lỗi vào collection health, admin sẽ thấy tại đây.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthItemCard extends StatelessWidget {
  const _HealthItemCard({required this.item});

  final SystemHealthItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(_severityIcon, color: _severityColor(colorScheme)),
        title: Text(
          item.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: item.severity, color: _severityColor(colorScheme)),
              _Chip(label: item.status, color: colorScheme.primary),
              _Chip(label: item.source, color: colorScheme.onSurfaceVariant),
              if (item.module.isNotEmpty)
                _Chip(label: item.module, color: colorScheme.secondary),
            ],
          ),
        ),
        trailing: Text(item.createdAt.isEmpty ? '-' : item.createdAt),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              item.message.isEmpty ? item.path : item.message,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              item.data.entries
                  .map((entry) => '${entry.key}: ${entry.value}')
                  .join('\n'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _severityIcon {
    switch (item.severity.toLowerCase()) {
      case 'critical':
      case 'fatal':
      case 'error':
        return Icons.error_outline;
      case 'warning':
      case 'warn':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _severityColor(ColorScheme colorScheme) {
    switch (item.severity.toLowerCase()) {
      case 'critical':
      case 'fatal':
      case 'error':
        return colorScheme.error;
      case 'warning':
      case 'warn':
        return const Color(0xFFB45309);
      default:
        return colorScheme.primary;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
