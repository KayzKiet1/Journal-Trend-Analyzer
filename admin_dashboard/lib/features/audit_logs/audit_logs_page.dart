import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'audit_logs_view_model.dart';

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
      title: 'Audit Logs',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.logs.isEmpty) {
            return const LoadingView();
          }

          if (_viewModel.errorMessage != null && _viewModel.logs.isEmpty) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_viewModel.logs.length} loaded logs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () => _viewModel.loadLogs(refresh: true),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_viewModel.errorMessage != null) ...[
                Text(
                  _viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Time')),
                      DataColumn(label: Text('Admin')),
                      DataColumn(label: Text('Action')),
                      DataColumn(label: Text('Target')),
                    ],
                    rows: _viewModel.logs
                        .map(
                          (log) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  log.createdAt.isEmpty ? '-' : log.createdAt,
                                ),
                              ),
                              DataCell(
                                Text(
                                  log.adminEmail.isEmpty ? '-' : log.adminEmail,
                                ),
                              ),
                              DataCell(Text(log.action)),
                              DataCell(SelectableText(log.target)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_viewModel.hasMore)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _viewModel.isLoading
                        ? null
                        : _viewModel.loadLogs,
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Load more'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
