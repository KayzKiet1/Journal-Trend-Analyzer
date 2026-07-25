import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'audit_logs_view_model.dart';
import '../../data/models/audit_log.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  late final AuditLogsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AuditLogsViewModel()..loadLogs(refresh: true);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Nhật ký hoạt động',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.logs.isEmpty) {
            return const LoadingView();
          }

          if (_viewModel.errorMessage != null && _viewModel.logs.isEmpty) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          return RefreshIndicator(
            onRefresh: () => _viewModel.loadLogs(refresh: true),
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                if (_viewModel.errorMessage != null) ...[
                  _buildErrorBanner(context),
                  const SizedBox(height: 16),
                ],
                _buildLogsTable(context),
                const SizedBox(height: 24),
                if (_viewModel.hasMore) _buildLoadMoreButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Logs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Theo dõi mọi thay đổi và hành động của quản trị viên trong hệ thống.',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: _viewModel.isLoading
              ? null
              : () => _viewModel.loadLogs(refresh: true),
          icon: const Icon(Icons.refresh),
          tooltip: 'Làm mới',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
            foregroundColor: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _viewModel.errorMessage!,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTable(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMaxHeight: 64,
          columnSpacing: 32,
          columns: const [
            DataColumn(
              label: Text(
                'THỜI GIAN',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'ADMIN',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'HÀNH ĐỘNG',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'MỤC TIÊU',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
          rows: _viewModel.logs
              .map((log) => _buildLogRow(context, log))
              .toList(),
        ),
      ),
    );
  }

  DataRow _buildLogRow(BuildContext context, AuditLog log) {
    return DataRow(
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(log.createdAt),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                _formatTime(log.createdAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                child: Text(
                  log.adminEmail.isNotEmpty
                      ? log.adminEmail[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                log.adminEmail.isEmpty ? 'Unknown' : log.adminEmail,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        DataCell(_ActionChip(action: log.action)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              log.target,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: _viewModel.isLoading ? null : _viewModel.loadLogs,
        icon: _viewModel.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.expand_more),
        label: const Text('Tải thêm nhật ký'),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoString.split('T').first;
    }
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString.contains('T')
          ? isoString.split('T').last.split('.').first
          : '';
    }
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action});
  final String action;

  @override
  Widget build(BuildContext context) {
    Color color = const Color(0xFF64748B);
    IconData icon = Icons.info_outline;

    if (action.toLowerCase().contains('delete') ||
        action.toLowerCase().contains('remove')) {
      color = const Color(0xFFEF4444);
      icon = Icons.delete_outline;
    } else if (action.toLowerCase().contains('create') ||
        action.toLowerCase().contains('add') ||
        action.toLowerCase().contains('send')) {
      color = const Color(0xFF10B981);
      icon = Icons.add_circle_outline;
    } else if (action.toLowerCase().contains('update') ||
        action.toLowerCase().contains('set')) {
      color = const Color(0xFFF59E0B);
      icon = Icons.edit_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            action,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
