import 'package:flutter/material.dart';

import '../../data/models/analytics_summary.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'analytics_view_model.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late final AnalyticsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AnalyticsViewModel()..loadSummary();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Analytics',
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
              padding: const EdgeInsets.all(24),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricTile(
                      label: 'Events',
                      value: '${summary.totalEvents}',
                    ),
                    _MetricTile(
                      label: 'Active users',
                      value: '${summary.activeUsers}',
                    ),
                    _MetricTile(
                      label: 'Today active',
                      value: '${summary.activeUsersToday}',
                    ),
                    _MetricTile(
                      label: '7d active',
                      value: '${summary.activeUsers7d}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _DailyEventsPanel(events: summary.dailyEvents),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _RankTable(title: 'Top events', items: summary.topEvents),
                    _RankTable(
                      title: 'Top journals/searches',
                      items: summary.topJournals,
                    ),
                  ],
                ),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyEventsPanel extends StatelessWidget {
  const _DailyEventsPanel({required this.events});

  final List<DailyEventMetric> events;

  @override
  Widget build(BuildContext context) {
    final maxCount = events.fold<int>(
      1,
      (max, event) => event.count > max ? event.count : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              const Text('No analytics events yet.')
            else
              ...events.map(
                (event) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 96, child: Text(event.date)),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: event.count / maxCount,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: 48, child: Text('${event.count}')),
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

class _RankTable extends StatelessWidget {
  const _RankTable({required this.title, required this.items});

  final String title;
  final List<CountMetric> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Text('No data yet.')
              else
                ...items.map(
                  (item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    trailing: Text('${item.count}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
