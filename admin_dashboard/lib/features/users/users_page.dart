import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/models/admin_user.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'users_view_model.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late final UsersViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UsersViewModel()..loadUsers();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Users',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.users.isEmpty) {
            return const LoadingView();
          }

          if (_viewModel.errorMessage != null && _viewModel.users.isEmpty) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          return RefreshIndicator(
            onRefresh: () => _viewModel.loadUsers(refresh: true),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_viewModel.users.length} loaded users',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _viewModel.isLoading
                          ? null
                          : () => _viewModel.loadUsers(refresh: true),
                      icon: const Icon(Icons.refresh),
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Verified')),
                        DataColumn(label: Text('Last sign in')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _viewModel.users
                          .map((user) => _buildUserRow(context, user))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_viewModel.hasMore)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _viewModel.isLoadingMore
                          ? null
                          : _viewModel.loadUsers,
                      icon: _viewModel.isLoadingMore
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more),
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

  DataRow _buildUserRow(BuildContext context, AdminUser user) {
    return DataRow(
      cells: [
        DataCell(Text(user.email.isEmpty ? user.uid : user.email)),
        DataCell(_RoleChip(isAdmin: user.isAdmin)),
        DataCell(_StatusChip(disabled: user.disabled)),
        DataCell(Icon(user.emailVerified ? Icons.check : Icons.close)),
        DataCell(Text(_shortDate(user.lastSignInTime))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Open user',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AdminRoutes.userDetail, arguments: user.uid),
                icon: const Icon(Icons.open_in_new),
              ),
              IconButton(
                tooltip: user.disabled ? 'Enable user' : 'Disable user',
                onPressed: () => _confirmAccountState(user),
                icon: Icon(user.disabled ? Icons.lock_open : Icons.lock),
              ),
              IconButton(
                tooltip: user.isAdmin ? 'Remove admin' : 'Make admin',
                onPressed: () => _confirmAdminState(user),
                icon: Icon(
                  user.isAdmin
                      ? Icons.admin_panel_settings
                      : Icons.admin_panel_settings_outlined,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAccountState(AdminUser user) async {
    final shouldDisable = !user.disabled;
    final confirmed = await _confirm(
      title: shouldDisable ? 'Disable user?' : 'Enable user?',
      message: user.email.isEmpty ? user.uid : user.email,
    );

    if (confirmed) {
      await _viewModel.setDisabled(user, shouldDisable);
    }
  }

  Future<void> _confirmAdminState(AdminUser user) async {
    final shouldBeAdmin = !user.isAdmin;
    final confirmed = await _confirm(
      title: shouldBeAdmin ? 'Grant admin access?' : 'Remove admin access?',
      message: user.email.isEmpty ? user.uid : user.email,
    );

    if (confirmed) {
      await _viewModel.setAdmin(user, shouldBeAdmin);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
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

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
        size: 18,
      ),
      label: Text(isAdmin ? 'Admin' : 'User'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.disabled});

  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        disabled ? Icons.lock : Icons.check_circle_outline,
        size: 18,
      ),
      label: Text(disabled ? 'Disabled' : 'Active'),
    );
  }
}

String _shortDate(String value) {
  if (value.isEmpty) {
    return '-';
  }
  return value.replaceAll(' GMT', '');
}
