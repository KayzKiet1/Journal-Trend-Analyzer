import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../data/models/storage_file.dart';
import '../../data/repositories/storage_repository.dart';
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
  String _uploadFolder = 'admin_uploads';

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
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _prefixController,
                      decoration: const InputDecoration(
                        labelText: 'Prefix',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
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
                  DropdownMenu<String>(
                    width: 190,
                    initialSelection: _uploadFolder,
                    label: const Text('Upload folder'),
                    onSelected: (value) {
                      if (value != null) {
                        setState(() => _uploadFolder = value);
                      }
                    },
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(
                        value: 'admin_uploads',
                        label: 'Admin uploads',
                      ),
                      DropdownMenuEntry(value: 'reports', label: 'Reports'),
                      DropdownMenuEntry(
                        value: 'announcements',
                        label: 'Announcements',
                      ),
                      DropdownMenuEntry(value: 'exports', label: 'Exports'),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _viewModel.isUploading ? null : _pickAndUpload,
                    icon: _viewModel.isUploading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: const Text('Upload'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_viewModel.lastUploadedPath != null) ...[
                Text('Uploaded: ${_viewModel.lastUploadedPath}'),
                const SizedBox(height: 12),
              ],
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

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(withData: true);
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      return;
    }

    await _viewModel.uploadFile(
      StorageUploadRequest(
        bytes: bytes,
        fileName: file.name,
        contentType: _contentType(file.name),
        folder: _uploadFolder,
      ),
    );
  }

  String _contentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.csv')) return 'text/csv';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
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
              if (file.uploadedByEmail.isNotEmpty)
                Text('Uploaded by ${file.uploadedByEmail}'),
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
