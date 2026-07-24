import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';
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
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      (user.email.isNotEmpty ? user.email : user.uid)
                          .substring(0, 1)
                          .toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email.isEmpty ? user.uid : user.email,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.displayName.isEmpty
                              ? user.uid
                              : user.displayName,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Admin access'),
                        value: user.isAdmin,
                        onChanged: _viewModel.isLoading
                            ? null
                            : (value) => _confirmAdmin(value),
                        secondary: const Icon(Icons.admin_panel_settings),
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Disabled'),
                        value: user.disabled,
                        onChanged: _viewModel.isLoading
                            ? null
                            : (value) => _confirmDisabled(value),
                        secondary: const Icon(Icons.lock_outline),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(label: 'UID', value: user.uid),
                      _InfoRow(
                        label: 'Email verified',
                        value: user.emailVerified ? 'Yes' : 'No',
                      ),
                      _InfoRow(label: 'Created', value: user.creationTime),
                      _InfoRow(
                        label: 'Last sign in',
                        value: user.lastSignInTime,
                      ),
                      _InfoRow(
                        label: 'Providers',
                        value: user.providerIds.isEmpty
                            ? '-'
                            : user.providerIds.join(', '),
                      ),
                    ],
                  ),
                ),
              ),
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
    );
    if (confirmed) {
      await _viewModel.setAdmin(value);
    }
  }

  Future<void> _confirmDisabled(bool value) async {
    final confirmed = await _confirm(
      title: value ? 'Disable user?' : 'Enable user?',
    );
    if (confirmed) {
      await _viewModel.setDisabled(value);
    }
  }

  Future<bool> _confirm({required String title}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}
