import 'package:flutter/material.dart';

import '../../data/models/storage_file.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'storage_view_model.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  late final StorageViewModel _viewModel;
  final _prefixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = StorageViewModel()..loadFiles();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Storage',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.files.isEmpty) {
            return const LoadingView();
          }

          if (_viewModel.errorMessage != null && _viewModel.files.isEmpty) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _prefixController,
                      decoration: const InputDecoration(
                        labelText: 'Prefix',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _viewModel.isLoading
                        ? null
                        : () => _viewModel.loadFiles(
                            prefix: _prefixController.text.trim(),
                            refresh: true,
                          ),
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_viewModel.errorMessage != null) ...[
                Text(
                  _viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _viewModel.files
                    .map(
                      (file) => _StorageFileCard(file: file, onDelete: _delete),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              if (_viewModel.hasMore)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _viewModel.isLoading
                        ? null
                        : () => _viewModel.loadFiles(
                            prefix: _prefixController.text.trim(),
                          ),
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

  Future<void> _delete(StorageFile file) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete storage file?'),
            content: Text(file.name),
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

    if (confirmed) {
      await _viewModel.deleteFile(file.name);
    }
  }
}

class _StorageFileCard extends StatelessWidget {
  const _StorageFileCard({required this.file, required this.onDelete});

  final StorageFile file;
  final ValueChanged<StorageFile> onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  child: file.isImage
                      ? Image.network(file.downloadUrl, fit: BoxFit.cover)
                      : const Icon(Icons.insert_drive_file_outlined, size: 48),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(file.name),
              const SizedBox(height: 8),
              Text('${file.contentType} • ${_formatBytes(file.size)}'),
              Text(file.updated.isEmpty ? '-' : file.updated),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Delete',
                  onPressed: () => onDelete(file),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}
