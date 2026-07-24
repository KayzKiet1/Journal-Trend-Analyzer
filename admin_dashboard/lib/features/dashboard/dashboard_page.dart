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
          if (summary == null) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            onRefresh: _viewModel.loadSummary,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _MetricTile(
                      label: 'Users',
                      value: summary.userCount.toString(),
                      icon: Icons.people_alt_outlined,
                    ),
                    _MetricTile(
                      label: 'Journals',
                      value: summary.journalCount.toString(),
                      icon: Icons.menu_book_outlined,
                    ),
                    _MetricTile(
                      label: 'Publications',
                      value: summary.publicationCount.toString(),
                      icon: Icons.article_outlined,
                    ),
                    _MetricTile(
                      label: 'Storage files',
                      value: summary.storageFileCount.toString(),
                      icon: Icons.folder_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Quick links',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _QuickLink(
                      label: 'Users',
                      routeName: AdminRoutes.users,
                      icon: Icons.people_alt_outlined,
                    ),
                    _QuickLink(
                      label: 'Firestore',
                      routeName: AdminRoutes.firestoreCollections,
                      icon: Icons.storage_outlined,
                    ),
                    _QuickLink(
                      label: 'Config',
                      routeName: AdminRoutes.appConfig,
                      icon: Icons.tune_outlined,
                    ),
                    _QuickLink(
                      label: 'Storage',
                      routeName: AdminRoutes.storage,
                      icon: Icons.folder_outlined,
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
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall,
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
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
