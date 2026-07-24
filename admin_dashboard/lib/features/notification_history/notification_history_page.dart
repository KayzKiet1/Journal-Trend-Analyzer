import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'notification_history_view_model.dart';

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  late final NotificationHistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = NotificationHistoryViewModel()..loadLogs(refresh: true);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Notification History',
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
                      '${_viewModel.logs.length} sent notifications',
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
                      DataColumn(label: Text('Target')),
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Body')),
                      DataColumn(label: Text('Result')),
                      DataColumn(label: Text('Admin')),
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
                                  _targetLabel(
                                    log.mode,
                                    log.target,
                                    log.targetEmail,
                                  ),
                                ),
                              ),
                              DataCell(Text(log.title)),
                              DataCell(
                                SizedBox(width: 260, child: Text(log.body)),
                              ),
                              DataCell(
                                Text(
                                  '${log.successCount} ok / ${log.failureCount} failed',
                                ),
                              ),
                              DataCell(Text(log.adminEmail)),
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

  String _targetLabel(String mode, String target, String email) {
    if (mode == 'allUsers') return 'All users';
    if (mode == 'user') return email.isEmpty ? target : email;
    return target;
  }
}
