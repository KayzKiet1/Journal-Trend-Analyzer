import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'firestore_manager_view_model.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  late final FirestoreManagerViewModel _viewModel;
  String? _collectionName;

  @override
  void initState() {
    super.initState();
    _viewModel = FirestoreManagerViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (_collectionName == null && argument is String) {
      _collectionName = argument;
      _viewModel.loadDocuments(argument, refresh: true);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionName = _collectionName;

    return AdminShell(
      title: collectionName ?? 'Documents',
      child: collectionName == null
          ? const ErrorView(message: 'Missing collection name.')
          : AnimatedBuilder(
              animation: _viewModel,
              builder: (context, _) {
                if (_viewModel.isLoading && _viewModel.documents.isEmpty) {
                  return const LoadingView();
                }

                if (_viewModel.errorMessage != null &&
                    _viewModel.documents.isEmpty) {
                  return ErrorView(message: _viewModel.errorMessage!);
                }

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_viewModel.documents.length} loaded documents',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _openDocument(collectionName, ''),
                          icon: const Icon(Icons.add),
                          label: const Text('New document'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_viewModel.errorMessage != null) ...[
                      Text(
                        _viewModel.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _viewModel.documents.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final document = _viewModel.documents[index];
                          return ListTile(
                            leading: const Icon(Icons.description_outlined),
                            title: Text(document.id),
                            subtitle: Text(document.path),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                _openDocument(collectionName, document.id),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_viewModel.hasMoreDocuments)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _viewModel.isLoading
                              ? null
                              : () => _viewModel.loadDocuments(collectionName),
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

  void _openDocument(String collectionName, String documentId) {
    Navigator.of(context).pushNamed(
      AdminRoutes.firestoreDocumentDetail,
      arguments: {'collectionName': collectionName, 'documentId': documentId},
    );
  }
}
