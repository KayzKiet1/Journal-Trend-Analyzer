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
      title: 'Quản lý người dùng',
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
              padding: const EdgeInsets.all(32),
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                if (_viewModel.errorMessage != null) ...[
                  _buildErrorBanner(context),
                  const SizedBox(height: 16),
                ],
                _buildUsersTable(context),
                const SizedBox(height: 24),
                if (_viewModel.hasMore) _buildLoadMoreButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = colorScheme.brightness == Brightness.dark
        ? Colors.white
        : colorScheme.onSurface;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danh sách người dùng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: titleColor,
              ),
            ),
            Text(
              'Hiển thị ${_viewModel.users.length} tài khoản trong hệ thống.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton.filledTonal(
          onPressed: _viewModel.isLoading
              ? null
              : () => _viewModel.loadUsers(refresh: true),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Làm mới',
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.24)),
      ),
      child: Text(
        _viewModel.errorMessage!,
        style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13),
      ),
    );
  }

  Widget _buildUsersTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            colorScheme.surfaceContainerLowest,
          ),
          headingTextStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          dataTextStyle: TextStyle(color: colorScheme.onSurface, fontSize: 13),
          dataRowMaxHeight: 64,
          columns: const [
            DataColumn(
              label: Text(
                'TÀI KHOẢN',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'VAI TRÒ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'TRẠNG THÁI',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'XÁC MINH',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'ĐĂNG NHẬP CUỐI',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'THAO TÁC',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          rows: _viewModel.users
              .map((user) => _buildUserRow(context, user))
              .toList(),
        ),
      ),
    );
  }

  DataRow _buildUserRow(BuildContext context, AdminUser user) {
    final colorScheme = Theme.of(context).colorScheme;

    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                child: Text(
                  user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                user.email.isEmpty ? user.uid : user.email,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        DataCell(_RoleChip(isAdmin: user.isAdmin)),
        DataCell(_StatusChip(disabled: user.disabled)),
        DataCell(
          Icon(
            user.emailVerified ? Icons.verified_rounded : Icons.pending_rounded,
            color: user.emailVerified ? Colors.blue : Colors.amber,
            size: 20,
          ),
        ),
        DataCell(
          Text(
            _shortDate(user.lastSignInTime),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Xem chi tiết',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AdminRoutes.userDetail, arguments: user.uid),
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
              ),
              IconButton(
                tooltip: user.disabled ? 'Mở khóa' : 'Khóa tài khoản',
                onPressed: () => _confirmAccountState(user),
                icon: Icon(
                  user.disabled
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  size: 20,
                ),
              ),
              IconButton(
                tooltip: user.isAdmin ? 'Gỡ Admin' : 'Cấp quyền Admin',
                onPressed: () => _confirmAdminState(user),
                icon: Icon(
                  user.isAdmin
                      ? Icons.admin_panel_settings
                      : Icons.admin_panel_settings_outlined,
                  size: 20,
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
      title: shouldDisable ? 'Khóa tài khoản?' : 'Mở khóa tài khoản?',
      message:
          'Hành động này sẽ ảnh hưởng đến khả năng truy cập của ${user.email}.',
    );
    if (confirmed) await _viewModel.setDisabled(user, shouldDisable);
  }

  Future<void> _confirmAdminState(AdminUser user) async {
    final shouldBeAdmin = !user.isAdmin;
    final confirmed = await _confirm(
      title: shouldBeAdmin ? 'Cấp quyền Admin?' : 'Gỡ quyền Admin?',
      message: 'Bạn có chắc chắn muốn thay đổi quyền hạn của tài khoản này?',
    );
    if (confirmed) await _viewModel.setAdmin(user, shouldBeAdmin);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildLoadMoreButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: _viewModel.isLoadingMore ? null : _viewModel.loadUsers,
        icon: _viewModel.isLoadingMore
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.expand_more_rounded),
        label: const Text('Tải thêm'),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.isAdmin});
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final neutralBackground = colorScheme.surfaceContainerHighest;
    final neutralForeground = colorScheme.onSurfaceVariant;
    const adminColor = Color(0xFF6366F1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin
            ? adminColor.withValues(alpha: 0.14)
            : neutralBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
            size: 14,
            color: isAdmin ? adminColor : neutralForeground,
          ),
          const SizedBox(width: 4),
          Text(
            isAdmin ? 'Admin' : 'User',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isAdmin ? adminColor : neutralForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.disabled});
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const activeColor = Color(0xFF047857);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: disabled
            ? colorScheme.errorContainer
            : activeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        disabled ? 'Bị khóa' : 'Hoạt động',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: disabled ? colorScheme.onErrorContainer : activeColor,
        ),
      ),
    );
  }
}

String _shortDate(String value) {
  if (value.isEmpty) return '-';
  return value.replaceAll(' GMT', '').split(' ').take(4).join(' ');
}
