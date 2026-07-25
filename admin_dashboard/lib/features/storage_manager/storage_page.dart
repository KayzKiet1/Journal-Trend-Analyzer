import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
  static const _folders = [
    StorageFolderOption(value: '', label: 'All files'),
    StorageFolderOption(value: 'admin_uploads', label: 'Admin uploads'),
    StorageFolderOption(value: 'reports', label: 'Reports'),
    StorageFolderOption(value: 'announcements', label: 'Announcements'),
    StorageFolderOption(value: 'exports', label: 'Exports'),
  ];

  late final StorageViewModel _viewModel;
  final _prefixController = TextEditingController();
  String _selectedFolder = '';
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

          final groups = _buildGroups(_viewModel.files);

          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              _StorageHeader(
                fileCount: _viewModel.files.length,
                totalBytes: _viewModel.totalBytes,
                isUploading: _viewModel.isUploading,
              ),
              const SizedBox(height: 16),
              _StorageToolbar(
                folders: _folders,
                selectedFolder: _selectedFolder,
                uploadFolder: _uploadFolder,
                prefixController: _prefixController,
                isLoading: _viewModel.isLoading,
                isUploading: _viewModel.isUploading,
                onFolderChanged: _selectFolder,
                onUploadFolderChanged: (value) {
                  setState(() => _uploadFolder = value);
                },
                onSearch: () => _viewModel.loadFiles(
                  prefix: _prefixController.text.trim(),
                  refresh: true,
                ),
                onUpload: _pickAndUpload,
              ),
              if (_viewModel.lastUploadedPath != null) ...[
                const SizedBox(height: 12),
                _StatusBanner(
                  icon: Icons.check_circle_outline,
                  text: 'Uploaded: ${_viewModel.lastUploadedPath}',
                  isError: false,
                ),
              ],
              if (_viewModel.errorMessage != null) ...[
                const SizedBox(height: 12),
                _StatusBanner(
                  icon: Icons.error_outline,
                  text: _viewModel.errorMessage!,
                  isError: true,
                ),
              ],
              const SizedBox(height: 16),
              if (_viewModel.files.isEmpty)
                const _EmptyStorageCard()
              else
                ...groups.map(
                  (folderGroup) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _FolderGroupCard(
                      group: folderGroup,
                      onDelete: _delete,
                    ),
                  ),
                ),
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

  void _selectFolder(String value) {
    setState(() => _selectedFolder = value);
    final prefix = value.isEmpty ? '' : '$value/';
    _prefixController.text = prefix;
    _viewModel.loadFiles(prefix: prefix, refresh: true);
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

    const maxUploadBytes = 8 * 1024 * 1024;
    if (bytes.length > maxUploadBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload limit is 8 MB per file from admin web.'),
        ),
      );
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

    if (_viewModel.lastUploadedPath != null) {
      final prefix = '$_uploadFolder/';
      setState(() {
        _selectedFolder = _uploadFolder;
        _prefixController.text = prefix;
      });
    }
  }

  List<StorageFolderGroup> _buildGroups(List<StorageFile> files) {
    final folderMap = <String, Map<String, List<StorageFile>>>{};
    for (final file in files) {
      final folder = file.folder.isEmpty ? '(root)' : file.folder;
      final owner = file.ownerLabel;
      folderMap.putIfAbsent(folder, () => {});
      folderMap[folder]!.putIfAbsent(owner, () => []);
      folderMap[folder]![owner]!.add(file);
    }

    final folders = folderMap.entries.map((folderEntry) {
      final owners = folderEntry.value.entries.map((ownerEntry) {
        final files = [...ownerEntry.value]
          ..sort((a, b) => b.updated.compareTo(a.updated));
        return StorageOwnerGroup(owner: ownerEntry.key, files: files);
      }).toList()..sort((a, b) => a.owner.compareTo(b.owner));

      return StorageFolderGroup(folder: folderEntry.key, owners: owners);
    }).toList()..sort((a, b) => a.folder.compareTo(b.folder));

    return folders;
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

class StorageFolderOption {
  const StorageFolderOption({required this.value, required this.label});

  final String value;
  final String label;
}

class StorageFolderGroup {
  const StorageFolderGroup({required this.folder, required this.owners});

  final String folder;
  final List<StorageOwnerGroup> owners;

  int get fileCount =>
      owners.fold(0, (total, owner) => total + owner.files.length);

  int get totalBytes => owners.fold(
    0,
    (total, owner) =>
        total + owner.files.fold(0, (sum, file) => sum + file.size),
  );
}

class StorageOwnerGroup {
  const StorageOwnerGroup({required this.owner, required this.files});

  final String owner;
  final List<StorageFile> files;
}

class _StorageHeader extends StatelessWidget {
  const _StorageHeader({
    required this.fileCount,
    required this.totalBytes,
    required this.isUploading,
  });

  final int fileCount;
  final int totalBytes;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.folder, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage manager',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$fileCount files • ${_formatBytes(totalBytes)} loaded',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isUploading)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _StorageToolbar extends StatelessWidget {
  const _StorageToolbar({
    required this.folders,
    required this.selectedFolder,
    required this.uploadFolder,
    required this.prefixController,
    required this.isLoading,
    required this.isUploading,
    required this.onFolderChanged,
    required this.onUploadFolderChanged,
    required this.onSearch,
    required this.onUpload,
  });

  final List<StorageFolderOption> folders;
  final String selectedFolder;
  final String uploadFolder;
  final TextEditingController prefixController;
  final bool isLoading;
  final bool isUploading;
  final ValueChanged<String> onFolderChanged;
  final ValueChanged<String> onUploadFolderChanged;
  final VoidCallback onSearch;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: folders
                  .map(
                    (folder) => ChoiceChip(
                      label: Text(folder.label),
                      selected: selectedFolder == folder.value,
                      onSelected: isLoading
                          ? null
                          : (_) => onFolderChanged(folder.value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: prefixController,
                    decoration: const InputDecoration(
                      labelText: 'Prefix',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: isLoading ? null : onSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
                DropdownMenu<String>(
                  width: 210,
                  initialSelection: uploadFolder,
                  label: const Text('Upload folder'),
                  onSelected: (value) {
                    if (value != null) {
                      onUploadFolderChanged(value);
                    }
                  },
                  dropdownMenuEntries: folders
                      .where((folder) => folder.value.isNotEmpty)
                      .map(
                        (folder) => DropdownMenuEntry(
                          value: folder.value,
                          label: folder.label,
                        ),
                      )
                      .toList(),
                ),
                FilledButton.icon(
                  onPressed: isUploading ? null : onUpload,
                  icon: isUploading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: const Text('Upload'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Upload path: $uploadFolder/{adminUid}/{timestamp}_{fileName}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderGroupCard extends StatelessWidget {
  const _FolderGroupCard({required this.group, required this.onDelete});

  final StorageFolderGroup group;
  final ValueChanged<StorageFile> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.folder,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${group.fileCount} files • ${_formatBytes(group.totalBytes)}',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...group.owners.map(
              (owner) => _OwnerSection(owner: owner, onDelete: onDelete),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerSection extends StatelessWidget {
  const _OwnerSection({required this.owner, required this.onDelete});

  final StorageOwnerGroup owner;
  final ValueChanged<StorageFile> onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      owner.owner,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text('${owner.files.length} files'),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: owner.files
                    .map(
                      (file) =>
                          _StorageFileCard(file: file, onDelete: onDelete),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageFileCard extends StatelessWidget {
  const _StorageFileCard({required this.file, required this.onDelete});

  final StorageFile file;
  final ValueChanged<StorageFile> onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: file.isImage && file.downloadUrl.isNotEmpty
                        ? Image.network(
                            file.downloadUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image_outlined),
                          )
                        : Icon(
                            _fileIcon(file.contentType),
                            size: 46,
                            color: colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                file.originalFileName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text('${file.contentType} • ${_formatBytes(file.size)}'),
              Text(file.updated.isEmpty ? '-' : file.updated),
              const SizedBox(height: 8),
              SelectableText(
                file.name,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
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

  IconData _fileIcon(String contentType) {
    if (contentType == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (contentType.startsWith('text/') || contentType.contains('csv')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.isError,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isError ? colorScheme.error : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(child: SelectableText(text)),
        ],
      ),
    );
  }
}

class _EmptyStorageCard extends StatelessWidget {
  const _EmptyStorageCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: Text('No files found for this prefix.')),
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
