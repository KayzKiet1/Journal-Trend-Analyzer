import 'package:flutter/material.dart';

import '../../data/models/admin_user.dart';
import '../../data/models/user_profile_summary.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/utils/url_opener.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'user_detail_view_model.dart';

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({super.key});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late final UserDetailViewModel _viewModel;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _viewModel = UserDetailViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (_uid == null && arguments is String && arguments.isNotEmpty) {
      _uid = arguments;
      _viewModel.loadUser(arguments);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'User Detail',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_uid == null) {
            return const ErrorView(message: 'Missing user id.');
          }

          if (_viewModel.isLoading && _viewModel.user == null) {
            return const LoadingView();
          }

          if (_viewModel.errorMessage != null && _viewModel.user == null) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          final user = _viewModel.user;
          if (user == null) {
            return const SizedBox.shrink();
          }

          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              _UserHero(user: user),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 980;
                  final access = _AccessCard(
                    user: user,
                    isLoading: _viewModel.isLoading,
                    onAdminChanged: _confirmAdmin,
                    onDisabledChanged: _confirmDisabled,
                  );
                  final identity = _IdentityCard(user: user);

                  if (!twoColumns) {
                    return Column(
                      children: [access, const SizedBox(height: 16), identity],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: access),
                      const SizedBox(width: 16),
                      Expanded(child: identity),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _UserProfileSections(summary: _viewModel.profileSummary),
              if (_viewModel.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmAdmin(bool value) async {
    final confirmed = await _confirm(
      title: value ? 'Grant admin access?' : 'Remove admin access?',
      content: value
          ? 'User sẽ có quyền vào admin dashboard sau khi refresh token.'
          : 'User sẽ mất quyền admin sau khi token được refresh.',
    );
    if (confirmed) {
      await _viewModel.setAdmin(value);
    }
  }

  Future<void> _confirmDisabled(bool value) async {
    final confirmed = await _confirm(
      title: value ? 'Disable user?' : 'Enable user?',
      content: value
          ? 'User sẽ không đăng nhập được nữa.'
          : 'User có thể đăng nhập lại nếu credential hợp lệ.',
    );
    if (confirmed) {
      await _viewModel.setDisabled(value);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _UserHero extends StatelessWidget {
  const _UserHero({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryText = user.email.isEmpty ? user.uid : user.email;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                primaryText.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    primaryText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    user.displayName.isEmpty ? user.uid : user.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _StatusChip(
              label: user.disabled ? 'Disabled' : 'Enabled',
              color: user.disabled ? colorScheme.error : colorScheme.primary,
            ),
            const SizedBox(width: 8),
            if (user.isAdmin)
              _StatusChip(label: 'Admin', color: colorScheme.tertiary),
          ],
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.user,
    required this.isLoading,
    required this.onAdminChanged,
    required this.onDisabledChanged,
  });

  final AdminUser user;
  final bool isLoading;
  final ValueChanged<bool> onAdminChanged;
  final ValueChanged<bool> onDisabledChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SwitchRow(
              title: 'Admin access',
              subtitle: 'Custom claim admin cho dashboard.',
              icon: Icons.admin_panel_settings_outlined,
              value: user.isAdmin,
              onChanged: isLoading ? null : onAdminChanged,
            ),
            const Divider(),
            _SwitchRow(
              title: 'Disabled',
              subtitle: 'Khóa hoặc mở khóa tài khoản Firebase Auth.',
              icon: Icons.lock_outline,
              value: user.disabled,
              onChanged: isLoading ? null : onDisabledChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Identity',
      icon: Icons.badge_outlined,
      children: [
        _InfoRow(label: 'UID', value: user.uid),
        _InfoRow(
          label: 'Email verified',
          value: user.emailVerified ? 'Yes' : 'No',
        ),
        _InfoRow(label: 'Created', value: user.creationTime),
        _InfoRow(label: 'Last sign in', value: user.lastSignInTime),
        _InfoRow(
          label: 'Providers',
          value: user.providerIds.isEmpty ? '-' : user.providerIds.join(', '),
        ),
      ],
    );
  }
}

class _UserProfileSections extends StatelessWidget {
  const _UserProfileSections({required this.summary});

  final UserProfileSummary? summary;
  static const _urlOpener = UrlOpener();

  @override
  Widget build(BuildContext context) {
    final data = summary;
    if (data == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MiniMetric(label: 'FCM tokens', value: '${data.fcmTokens.length}'),
            _MiniMetric(label: 'Activity', value: '${data.activity.length}'),
            _MiniMetric(label: 'Reports', value: '${data.reports.length}'),
            _MiniMetric(
              label: 'Saved items',
              value:
                  '${data.savedJournals.length + data.savedPublications.length}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Recent activity',
          icon: Icons.timeline_outlined,
          children: data.activity.isEmpty
              ? const [_MutedText('No analytics activity yet.')]
              : data.activity
                    .take(10)
                    .map(
                      (event) => _InfoRow(
                        label: event.data['eventName']?.toString() ?? event.id,
                        value:
                            event.data['createdAt']?.toString() ??
                            event.data['metadata']?.toString() ??
                            '-',
                      ),
                    )
                    .toList(),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 980;
            final tokens = _SectionCard(
              title: 'FCM tokens',
              icon: Icons.notifications_active_outlined,
              children: data.fcmTokens.isEmpty
                  ? const [_MutedText('No registered tokens.')]
                  : data.fcmTokens
                        .map(
                          (token) => _InfoRow(
                            label: token.id,
                            value:
                                token.data['platform']?.toString() ??
                                token.data['updatedAt']?.toString() ??
                                '-',
                          ),
                        )
                        .toList(),
            );
            final reports = _SectionCard(
              title: 'Uploaded reports',
              icon: Icons.picture_as_pdf_outlined,
              children: data.reports.isEmpty
                  ? const [_MutedText('No uploaded reports.')]
                  : data.reports
                        .map(
                          (report) => _ReportRow(
                            report: report,
                            onOpen: report.downloadUrl.isEmpty
                                ? null
                                : () => _openUrl(context, report.downloadUrl),
                          ),
                        )
                        .toList(),
            );

            if (!twoColumns) {
              return Column(
                children: [tokens, const SizedBox(height: 16), reports],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tokens),
                const SizedBox(width: 16),
                Expanded(child: reports),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Saved journals/publications',
          icon: Icons.bookmark_outline,
          children: _savedItems(data),
        ),
      ],
    );
  }

  static List<Widget> _savedItems(UserProfileSummary data) {
    final rows = <Widget>[
      _InfoRow(label: 'Saved journals', value: '${data.savedJournals.length}'),
      _InfoRow(
        label: 'Saved publications',
        value: '${data.savedPublications.length}',
      ),
      const Divider(),
    ];

    if (data.savedJournals.isEmpty && data.savedPublications.isEmpty) {
      rows.add(const _MutedText('No saved journals or publications.'));
      return rows;
    }

    rows.addAll(
      data.savedJournals.map(
        (document) => _SavedItemRow(
          type: 'Journal',
          title:
              document.data['name']?.toString() ??
              document.data['displayName']?.toString() ??
              document.data['itemId']?.toString() ??
              document.id,
          subtitle: document.data['publisher']?.toString() ?? document.path,
          savedAt: document.data['savedAt']?.toString() ?? '',
        ),
      ),
    );
    rows.addAll(
      data.savedPublications.map(
        (document) => _SavedItemRow(
          type: 'Publication',
          title:
              document.data['title']?.toString() ??
              document.data['publicationTitle']?.toString() ??
              document.data['itemId']?.toString() ??
              document.id,
          subtitle:
              document.data['journalName']?.toString() ??
              document.data['doi']?.toString() ??
              document.path,
          savedAt: document.data['savedAt']?.toString() ?? '',
        ),
      ),
    );
    return rows;
  }

  static Future<void> _openUrl(BuildContext context, String url) async {
    try {
      await _urlOpener.open(url);
    } on Exception catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.onOpen});

  final UserReportFile report;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.picture_as_pdf_outlined),
      title: SelectableText(
        report.originalFileName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${_formatBytes(report.size)} • ${report.updated}'),
      trailing: IconButton(
        tooltip: onOpen == null ? 'Signed URL unavailable' : 'Open file',
        onPressed: onOpen,
        icon: const Icon(Icons.open_in_new),
      ),
    );
  }
}

class _SavedItemRow extends StatelessWidget {
  const _SavedItemRow({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.savedAt,
  });

  final String type;
  final String title;
  final String subtitle;
  final String savedAt;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.bookmark_outline, color: colorScheme.primary),
      title: SelectableText(
        title.isEmpty ? '-' : title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          type,
          if (subtitle.isNotEmpty) subtitle,
          if (savedAt.isNotEmpty) savedAt,
        ].join(' • '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
