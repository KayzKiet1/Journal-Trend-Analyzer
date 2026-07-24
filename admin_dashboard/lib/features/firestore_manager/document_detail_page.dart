import 'dart:convert';

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
  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, bool> _boolFields = {};
  String? _collectionName;

  DocumentSchema? get _schema => _schemas[_collectionName];

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
    _initSchemaControllers(const {});

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
              setState(() => _initSchemaControllers(document.data));
            }
          });
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _documentIdController.dispose();
    _jsonController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
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
                  padding: const EdgeInsets.all(28),
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DocumentHeader(
                            collectionName: collectionName,
                            documentIdController: _documentIdController,
                            isExisting: _viewModel.selectedDocument != null,
                          ),
                          if (_schema != null) ...[
                            const SizedBox(height: 16),
                            _ManagedFieldsCard(
                              schema: _schema!,
                              textControllers: _fieldControllers,
                              boolFields: _boolFields,
                              onBoolChanged: (key, value) {
                                setState(() => _boolFields[key] = value);
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          _AdvancedJsonCard(controller: _jsonController),
                          if (_viewModel.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _viewModel.errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: _viewModel.isLoading ? null : _save,
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Save document'),
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
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _initSchemaControllers(Map<String, dynamic> data) {
    final schema = _schema;
    if (schema == null) {
      return;
    }

    for (final field in schema.fields) {
      if (field.type == DocumentFieldType.boolean) {
        _boolFields[field.key] = data[field.key] == true;
        continue;
      }

      final controller = _fieldControllers.putIfAbsent(
        field.key,
        TextEditingController.new,
      );
      controller.text = data[field.key]?.toString() ?? field.defaultValue;
    }
  }

  Future<void> _save() async {
    final collectionName = _collectionName;
    final documentId = _documentIdController.text.trim();
    if (collectionName == null || documentId.isEmpty) {
      return;
    }

    final payload = _buildPayload();
    if (payload == null) {
      return;
    }

    await _viewModel.saveDocument(
      collectionName: collectionName,
      documentId: documentId,
      jsonText: const JsonEncoder.withIndent('  ').convert(payload),
    );

    final document = _viewModel.selectedDocument;
    if (mounted && document != null && _viewModel.errorMessage == null) {
      _jsonController.text = _viewModel.prettyJson(document.data);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document saved.')));
    }
  }

  Map<String, dynamic>? _buildPayload() {
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(
        _jsonController.text.trim().isEmpty ? '{}' : _jsonController.text,
      );
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Document JSON must be an object.');
      }
      data = decoded;
    } on FormatException catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return null;
    }

    final schema = _schema;
    if (schema == null) {
      return data;
    }

    for (final field in schema.fields) {
      switch (field.type) {
        case DocumentFieldType.text:
          data[field.key] = _fieldControllers[field.key]?.text.trim() ?? '';
        case DocumentFieldType.number:
          data[field.key] =
              num.tryParse(_fieldControllers[field.key]?.text.trim() ?? '') ??
              0;
        case DocumentFieldType.boolean:
          data[field.key] = _boolFields[field.key] == true;
      }
    }

    return data;
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

class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({
    required this.collectionName,
    required this.documentIdController,
    required this.isExisting,
  });

  final String collectionName;
  final TextEditingController documentIdController;
  final bool isExisting;

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
                Icon(Icons.description_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    collectionName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: documentIdController,
              enabled: !isExisting,
              decoration: const InputDecoration(
                labelText: 'Document ID',
                prefixIcon: Icon(Icons.tag_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagedFieldsCard extends StatelessWidget {
  const _ManagedFieldsCard({
    required this.schema,
    required this.textControllers,
    required this.boolFields,
    required this.onBoolChanged,
  });

  final DocumentSchema schema;
  final Map<String, TextEditingController> textControllers;
  final Map<String, bool> boolFields;
  final void Function(String key, bool value) onBoolChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schema.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              schema.description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...schema.fields.map((field) {
              if (field.type == DocumentFieldType.boolean) {
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(field.label),
                  subtitle: Text(field.helpText),
                  value: boolFields[field.key] == true,
                  onChanged: (value) => onBoolChanged(field.key, value),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextField(
                  controller: textControllers[field.key],
                  keyboardType: field.type == DocumentFieldType.number
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: field.label,
                    helperText: field.helpText,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AdvancedJsonCard extends StatelessWidget {
  const _AdvancedJsonCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: TextField(
          controller: controller,
          minLines: 14,
          maxLines: 24,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.35,
          ),
          decoration: const InputDecoration(
            labelText: 'Advanced JSON',
            alignLabelWithHint: true,
          ),
        ),
      ),
    );
  }
}

enum DocumentFieldType { text, number, boolean }

class DocumentSchema {
  const DocumentSchema({
    required this.title,
    required this.description,
    required this.fields,
  });

  final String title;
  final String description;
  final List<DocumentFieldSchema> fields;
}

class DocumentFieldSchema {
  const DocumentFieldSchema({
    required this.key,
    required this.label,
    required this.type,
    required this.helpText,
    this.defaultValue = '',
  });

  final String key;
  final String label;
  final DocumentFieldType type;
  final String helpText;
  final String defaultValue;
}

const _schemas = {
  'users': DocumentSchema(
    title: 'Managed user fields',
    description: 'Các trường hồ sơ người dùng thường cần chỉnh.',
    fields: [
      DocumentFieldSchema(
        key: 'displayName',
        label: 'Display name',
        type: DocumentFieldType.text,
        helpText: 'Tên hiển thị trong app.',
      ),
      DocumentFieldSchema(
        key: 'email',
        label: 'Email',
        type: DocumentFieldType.text,
        helpText: 'Email nghiệp vụ trong Firestore profile.',
      ),
      DocumentFieldSchema(
        key: 'role',
        label: 'Role',
        type: DocumentFieldType.text,
        helpText: 'Ví dụ: user, researcher, admin.',
        defaultValue: 'user',
      ),
      DocumentFieldSchema(
        key: 'isActive',
        label: 'Active profile',
        type: DocumentFieldType.boolean,
        helpText: 'Trạng thái profile nghiệp vụ.',
      ),
    ],
  ),
  'journals': DocumentSchema(
    title: 'Managed journal fields',
    description: 'Các trường journal thường dùng trong màn hình nghiệp vụ.',
    fields: [
      DocumentFieldSchema(
        key: 'name',
        label: 'Journal name',
        type: DocumentFieldType.text,
        helpText: 'Tên journal.',
      ),
      DocumentFieldSchema(
        key: 'publisher',
        label: 'Publisher',
        type: DocumentFieldType.text,
        helpText: 'Nhà xuất bản.',
      ),
      DocumentFieldSchema(
        key: 'issn',
        label: 'ISSN',
        type: DocumentFieldType.text,
        helpText: 'Mã ISSN nếu có.',
      ),
      DocumentFieldSchema(
        key: 'impactScore',
        label: 'Impact score',
        type: DocumentFieldType.number,
        helpText: 'Chỉ số tham khảo cho ranking.',
      ),
    ],
  ),
  'trends': DocumentSchema(
    title: 'Managed trend fields',
    description: 'Các trường trend được admin kiểm soát.',
    fields: [
      DocumentFieldSchema(
        key: 'keyword',
        label: 'Keyword',
        type: DocumentFieldType.text,
        helpText: 'Từ khóa trend.',
      ),
      DocumentFieldSchema(
        key: 'category',
        label: 'Category',
        type: DocumentFieldType.text,
        helpText: 'Nhóm/chủ đề.',
      ),
      DocumentFieldSchema(
        key: 'score',
        label: 'Score',
        type: DocumentFieldType.number,
        helpText: 'Điểm trend.',
      ),
      DocumentFieldSchema(
        key: 'visible',
        label: 'Visible',
        type: DocumentFieldType.boolean,
        helpText: 'Cho phép hiển thị trend.',
      ),
    ],
  ),
  'configs': DocumentSchema(
    title: 'Managed config fields',
    description: 'Form config an toàn cho các document cấu hình đơn giản.',
    fields: [
      DocumentFieldSchema(
        key: 'key',
        label: 'Key',
        type: DocumentFieldType.text,
        helpText: 'Tên khóa cấu hình.',
      ),
      DocumentFieldSchema(
        key: 'value',
        label: 'Value',
        type: DocumentFieldType.text,
        helpText: 'Giá trị cấu hình dạng text.',
      ),
      DocumentFieldSchema(
        key: 'enabled',
        label: 'Enabled',
        type: DocumentFieldType.boolean,
        helpText: 'Bật/tắt config này.',
      ),
    ],
  ),
};
