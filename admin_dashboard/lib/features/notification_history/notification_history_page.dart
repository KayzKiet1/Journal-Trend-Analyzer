import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/models/notification_log.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'notification_history_view_model.dart';

enum NotificationModeFilter { all, allUsers, user }

enum NotificationResultFilter { all, success, failed }

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  late final NotificationHistoryViewModel _viewModel;
  NotificationModeFilter _modeFilter = NotificationModeFilter.all;
  NotificationResultFilter _resultFilter = NotificationResultFilter.all;

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

          final logs = _filteredLogs;

          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              _HistoryHeader(
                totalCount: _viewModel.logs.length,
                visibleCount: logs.length,
                modeFilter: _modeFilter,
                resultFilter: _resultFilter,
                onModeChanged: (value) => setState(() => _modeFilter = value),
                onResultChanged: (value) =>
                    setState(() => _resultFilter = value),
                onRefresh: () => _viewModel.loadLogs(refresh: true),
              ),
              const SizedBox(height: 16),
              if (_viewModel.errorMessage != null) ...[
                Text(
                  _viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              if (logs.isEmpty)
                const _EmptyHistoryCard()
              else
                ...logs.map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationLogCard(
                      log: log,
                      onDuplicate: () => _duplicateLog(log),
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

  List<NotificationLog> get _filteredLogs {
    return _viewModel.logs.where((log) {
      final modeMatches = switch (_modeFilter) {
        NotificationModeFilter.all => true,
        NotificationModeFilter.allUsers => log.mode == 'allUsers',
        NotificationModeFilter.user => log.mode == 'user',
      };
      final resultMatches = switch (_resultFilter) {
        NotificationResultFilter.all => true,
        NotificationResultFilter.success => log.failureCount == 0,
        NotificationResultFilter.failed => log.failureCount > 0,
      };

      return modeMatches && resultMatches;
    }).toList();
  }

  void _duplicateLog(NotificationLog log) {
    Navigator.of(context).pushNamed(
      AdminRoutes.messaging,
      arguments: {
        'mode': log.mode == 'user' ? 'user' : 'allUsers',
        'recipient': log.targetEmail.isNotEmpty ? log.targetEmail : log.target,
        'title': log.title,
        'body': log.body,
      },
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.totalCount,
    required this.visibleCount,
    required this.modeFilter,
    required this.resultFilter,
    required this.onModeChanged,
    required this.onResultChanged,
    required this.onRefresh,
  });

  final int totalCount;
  final int visibleCount;
  final NotificationModeFilter modeFilter;
  final NotificationResultFilter resultFilter;
  final ValueChanged<NotificationModeFilter> onModeChanged;
  final ValueChanged<NotificationResultFilter> onResultChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mark_email_read, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$visibleCount / $totalCount notifications',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<NotificationModeFilter>(
                  segments: const [
                    ButtonSegment(
                      value: NotificationModeFilter.all,
                      label: Text('All'),
                    ),
                    ButtonSegment(
                      value: NotificationModeFilter.allUsers,
                      label: Text('Users'),
                    ),
                    ButtonSegment(
                      value: NotificationModeFilter.user,
                      label: Text('User'),
                    ),
                  ],
                  selected: {modeFilter},
                  onSelectionChanged: (value) => onModeChanged(value.single),
                ),
                SegmentedButton<NotificationResultFilter>(
                  segments: const [
                    ButtonSegment(
                      value: NotificationResultFilter.all,
                      label: Text('All result'),
                    ),
                    ButtonSegment(
                      value: NotificationResultFilter.success,
                      label: Text('Success'),
                    ),
                    ButtonSegment(
                      value: NotificationResultFilter.failed,
                      label: Text('Failed'),
                    ),
                  ],
                  selected: {resultFilter},
                  onSelectionChanged: (value) => onResultChanged(value.single),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationLogCard extends StatelessWidget {
  const _NotificationLogCard({required this.log, required this.onDuplicate});

  final NotificationLog log;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasFailure = log.failureCount > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hasFailure ? Icons.error_outline : Icons.check_circle_outline,
              color: hasFailure ? colorScheme.error : colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.title.isEmpty ? '(no title)' : log.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _ResultChip(
                        text:
                            '${log.successCount} ok / ${log.failureCount} failed',
                        color: hasFailure
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                      IconButton(
                        tooltip: 'Nhân bản thông báo',
                        onPressed: onDuplicate,
                        icon: const Icon(Icons.content_copy_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(log.body),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(label: _targetLabel(log)),
                      _MetaChip(
                        label: log.createdAt.isEmpty ? '-' : log.createdAt,
                      ),
                      _MetaChip(
                        label: log.adminEmail.isEmpty ? '-' : log.adminEmail,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _targetLabel(NotificationLog log) {
    if (log.mode == 'allUsers') return 'All users';
    if (log.mode == 'user') {
      return log.targetEmail.isEmpty ? log.target : log.targetEmail;
    }
    return log.target;
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No notifications match this filter.')),
      ),
    );
  }
}
