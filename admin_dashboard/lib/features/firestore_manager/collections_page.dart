import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'firestore_manager_view_model.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  late final FirestoreManagerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = FirestoreManagerViewModel()..loadCollections();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Firestore Collections',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.collections.isEmpty) {
            return const LoadingView();
          }

          if (_viewModel.errorMessage != null &&
              _viewModel.collections.isEmpty) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Managed collections',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _viewModel.loadCollections,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _viewModel.collections
                    .map(
                      (collection) => SizedBox(
                        width: 260,
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.table_rows_outlined),
                            title: Text(collection.name),
                            subtitle: Text('${collection.count} documents'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).pushNamed(
                              AdminRoutes.firestoreDocuments,
                              arguments: collection.name,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
