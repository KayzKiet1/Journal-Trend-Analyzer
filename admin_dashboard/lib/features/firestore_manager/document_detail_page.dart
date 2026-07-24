import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'firestore_manager_view_model.dart';

class DocumentDetailPage extends StatefulWidget {
  const DocumentDetailPage({super.key});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  late final FirestoreManagerViewModel _viewModel;
  final _documentIdController = TextEditingController();
  final _jsonController = TextEditingController(text: '{}');
  String? _collectionName;

  @override
  void initState() {
    super.initState();
    _viewModel = FirestoreManagerViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (_collectionName != null || arguments is! Map) {
      return;
    }

    _collectionName = arguments['collectionName']?.toString();
    final documentId = arguments['documentId']?.toString() ?? '';
    _documentIdController.text = documentId;

    if (_collectionName != null && documentId.isNotEmpty) {
      _viewModel
          .loadDocument(
            collectionName: _collectionName!,
            documentId: documentId,
          )
          .then((_) {
            final document = _viewModel.selectedDocument;
            if (mounted && document != null) {
              _jsonController.text = _viewModel.prettyJson(document.data);
            }
          });
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _documentIdController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionName = _collectionName;

    return AdminShell(
      title: 'Document Detail',
      child: collectionName == null
          ? const ErrorView(message: 'Missing document context.')
          : AnimatedBuilder(
              animation: _viewModel,
              builder: (context, _) {
                if (_viewModel.isLoading &&
                    _viewModel.selectedDocument == null &&
                    _documentIdController.text.isNotEmpty) {
                  return const LoadingView();
                }

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    TextField(
                      controller: _documentIdController,
                      enabled: _viewModel.selectedDocument == null,
                      decoration: const InputDecoration(
                        labelText: 'Document ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _jsonController,
                      minLines: 14,
                      maxLines: 24,
                      decoration: const InputDecoration(
                        labelText: 'Document JSON',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
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
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: _viewModel.isLoading ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _viewModel.isLoading ||
                                  _documentIdController.text.isEmpty
                              ? null
                              : _delete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _save() async {
    final collectionName = _collectionName;
    final documentId = _documentIdController.text.trim();
    if (collectionName == null || documentId.isEmpty) {
      return;
    }

    await _viewModel.saveDocument(
      collectionName: collectionName,
      documentId: documentId,
      jsonText: _jsonController.text,
    );
  }

  Future<void> _delete() async {
    final collectionName = _collectionName;
    final documentId = _documentIdController.text.trim();
    if (collectionName == null || documentId.isEmpty) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete document?'),
            content: Text('$collectionName/$documentId'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await _viewModel.deleteDocument(
      collectionName: collectionName,
      documentId: documentId,
    );
    if (mounted && _viewModel.errorMessage == null) {
      Navigator.of(context).pop();
    }
  }
}
