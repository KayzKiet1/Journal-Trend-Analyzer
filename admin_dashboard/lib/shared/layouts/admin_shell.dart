import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/repositories/auth_repository.dart';
import 'sidebar.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  _AdminShellState() : _authRepository = FirebaseAuthRepository();

  final AuthRepository _authRepository;
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 1100;
    final currentRoute =
        ModalRoute.of(context)?.settings.name ?? AdminRoutes.dashboard;
    final theme = Theme.of(context);
    final gradients = theme.extension<AdminGradientTheme>()!;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => _buildMenuButton(context, isMobile),
        ),
        title: Text(widget.title),
        actions: [
          _buildThemeToggle(context),
          const SizedBox(width: 4),
          _buildAuthAction(context),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isMobile
          ? Sidebar(currentRoute: currentRoute, isCollapsed: false)
          : null,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(gradient: gradients.shellBackground),
        child: Row(
          children: [
            if (!isMobile)
              Sidebar(
                currentRoute: currentRoute,
                isCollapsed: _isSidebarCollapsed,
              ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                margin: isMobile
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(right: 16, bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: isMobile
                      ? BorderRadius.zero
                      : BorderRadius.circular(12),
                  border: isMobile
                      ? null
                      : Border.all(color: colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, bool isMobile) {
    return IconButton(
      tooltip: isMobile
          ? 'Mở menu'
          : (_isSidebarCollapsed ? 'Mở rộng sidebar' : 'Thu gọn sidebar'),
      onPressed: isMobile
          ? () => Scaffold.of(context).openDrawer()
          : () {
              setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
            },
      icon: const Icon(Icons.menu_rounded),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final theme = Theme.of(context);
    final gradients = theme.extension<AdminGradientTheme>()!;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: adminThemeMode,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        return Tooltip(
          message: isDark ? 'Chuyển giao diện sáng' : 'Chuyển giao diện tối',
          child: InkWell(
            onTap: () {
              adminThemeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              width: 44,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: gradients.primaryAccent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  key: ValueKey(isDark),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthAction(BuildContext context) {
    return StreamBuilder(
      initialData: _authRepository.currentUser,
      stream: _authRepository.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();

        final displayName = user.displayName ?? 'Tài khoản admin';
        final email = user.email ?? '';
        final avatarText = (displayName.isNotEmpty ? displayName : email)
            .characters
            .first
            .toUpperCase();
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return MenuAnchor(
          builder: (context, controller, child) {
            return InkWell(
              onTap: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Text(
                        avatarText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ],
                ),
              ),
            );
          },
          menuChildren: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            MenuItemButton(
              leadingIcon: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: Color(0xFFDC2626),
              ),
              onPressed: () async {
                await _authRepository.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AdminRoutes.login,
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
