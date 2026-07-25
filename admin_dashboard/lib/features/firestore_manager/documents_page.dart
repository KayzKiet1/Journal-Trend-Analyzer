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

  _CollectionPurpose get _purpose =>
      _collectionPurposes[_collectionName] ?? _CollectionPurpose.generic();

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

                return RefreshIndicator(
                  onRefresh: () =>
                      _viewModel.loadDocuments(collectionName, refresh: true),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _DocumentsHeader(
                        collectionName: collectionName,
                        purpose: _purpose,
                        count: _viewModel.documents.length,
                        isLoading: _viewModel.isLoading,
                        onRefresh: () => _viewModel.loadDocuments(
                          collectionName,
                          refresh: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_viewModel.errorMessage != null) ...[
                        Text(
                          _viewModel.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_viewModel.documents.isEmpty)
                        _EmptyDocumentsCard(purpose: _purpose)
                      else
                        Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _viewModel.documents.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final document = _viewModel.documents[index];
                              return ListTile(
                                leading: Icon(_purpose.icon),
                                title: Text(document.id),
                                subtitle: Text(
                                  _documentSubtitle(document.data),
                                ),
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
                                : () =>
                                      _viewModel.loadDocuments(collectionName),
                            icon: const Icon(Icons.expand_more),
                            label: const Text('Load more'),
                          ),
                        ),
                    ],
                  ),
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

  String _documentSubtitle(Map<String, dynamic> data) {
    final candidates = [
      data['title'],
      data['name'],
      data['email'],
      data['eventName'],
      data['action'],
      data['status'],
      data['createdAt'],
      data['updatedAt'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return 'View document fields';
  }
}

class _DocumentsHeader extends StatelessWidget {
  const _DocumentsHeader({
    required this.collectionName,
    required this.purpose,
    required this.count,
    required this.isLoading,
    required this.onRefresh,
  });

  final String collectionName;
  final _CollectionPurpose purpose;
  final int count;
  final bool isLoading;
  final VoidCallback onRefresh;

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
                color: colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(purpose.icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collectionName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    purpose.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$count loaded documents',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: isLoading ? null : onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDocumentsCard extends StatelessWidget {
  const _EmptyDocumentsCard({required this.purpose});

  final _CollectionPurpose purpose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(purpose.icon, size: 42, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No documents to manage here.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              purpose.emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionPurpose {
  const _CollectionPurpose({
    required this.icon,
    required this.description,
    required this.emptyMessage,
  });

  factory _CollectionPurpose.generic() {
    return const _CollectionPurpose(
      icon: Icons.description_outlined,
      description: 'Top-level Firestore collection managed by admin.',
      emptyMessage:
          'This collection is empty. Creation is intentionally disabled here to avoid accidental data.',
    );
  }

  final IconData icon;
  final String description;
  final String emptyMessage;
}

const _collectionPurposes = {
  'users': _CollectionPurpose(
    icon: Icons.group_outlined,
    description:
        'Business user profiles. Auth permission is managed in the Users page.',
    emptyMessage:
        'No Firestore user profiles exist yet. Firebase Auth users are still visible in Users.',
  ),
  'publications': _CollectionPurpose(
    icon: Icons.article_outlined,
    description:
        'Top-level publication records. User bookmarks are stored under each user profile, not here.',
    emptyMessage:
        'No top-level publication records exist. To view publication bookmarks, open Users > user detail.',
  ),
  'journals': _CollectionPurpose(
    icon: Icons.menu_book_outlined,
    description:
        'Top-level journal records. User saved journals are stored under each user profile.',
    emptyMessage:
        'No top-level journal records exist. To view saved journals, open Users > user detail.',
  ),
  'analytics_events': _CollectionPurpose(
    icon: Icons.analytics_outlined,
    description:
        'Raw product events written by the mobile app and summarized in Analytics.',
    emptyMessage:
        'No analytics events yet. Use the mobile app with a signed-in user to generate activity.',
  ),
  'app_config': _CollectionPurpose(
    icon: Icons.tune_outlined,
    description:
        'Internal Firestore app config. Runtime mobile config is managed in App Config.',
    emptyMessage: 'No Firestore config document exists yet.',
  ),
  'auditLogs': _CollectionPurpose(
    icon: Icons.history_outlined,
    description: 'Admin action logs. Prefer the Audit Logs page for review.',
    emptyMessage: 'No admin audit logs yet.',
  ),
  'notificationLogs': _CollectionPurpose(
    icon: Icons.mark_email_read_outlined,
    description:
        'Notification send history. Prefer Notification History for review.',
    emptyMessage: 'No notification history yet.',
  ),
  'system_health': _CollectionPurpose(
    icon: Icons.monitor_heart_outlined,
    description: 'System health documents and operational incidents.',
    emptyMessage: 'No system health events yet.',
  ),
};
