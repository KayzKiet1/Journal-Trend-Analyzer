import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/repositories/auth_repository.dart';

class Sidebar extends StatelessWidget {
  Sidebar({
    required this.currentRoute,
    required this.isCollapsed,
    super.key,
    AuthRepository? authRepository,
  }) : _authRepository = authRepository ?? FirebaseAuthRepository();

  final String currentRoute;
  final bool isCollapsed;
  final AuthRepository _authRepository;

  static const _accentColor = Color(0xFF4F46E5);
  static const _background = Color(0xFF111827);
  static const _mutedText = Color(0xFFCBD5E1);
  static const _sectionText = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: isCollapsed ? 80 : 280,
      color: _background,
      child: ClipRect(
        child: Column(
          children: [
            _SidebarHeader(isCollapsed: isCollapsed),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  isCollapsed ? 10 : 14,
                  14,
                  isCollapsed ? 10 : 14,
                  24,
                ),
                children: [
                  _SidebarSection(label: 'Chính', isCollapsed: isCollapsed),
                  _SidebarItem(
                    label: 'Dashboard',
                    icon: Icons.grid_view_rounded,
                    routeName: AdminRoutes.dashboard,
                    isActive: currentRoute == AdminRoutes.dashboard,
                    isCollapsed: isCollapsed,
                  ),
                  _SidebarItem(
                    label: 'Phân tích',
                    icon: Icons.insert_chart_outlined_rounded,
                    routeName: AdminRoutes.analytics,
                    isActive: currentRoute == AdminRoutes.analytics,
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 22),
                  _SidebarSection(label: 'Quản lý', isCollapsed: isCollapsed),
                  _SidebarItem(
                    label: 'Người dùng',
                    icon: Icons.group_outlined,
                    routeName: AdminRoutes.users,
                    isActive: currentRoute.startsWith(AdminRoutes.users),
                    isCollapsed: isCollapsed,
                  ),
                  _SidebarItem(
                    label: 'Firestore',
                    icon: Icons.storage_outlined,
                    routeName: AdminRoutes.firestoreCollections,
                    isActive: currentRoute.startsWith(
                      AdminRoutes.firestoreCollections,
                    ),
                    isCollapsed: isCollapsed,
                  ),
                  _SidebarItem(
                    label: 'Storage',
                    icon: Icons.folder_outlined,
                    routeName: AdminRoutes.storage,
                    isActive: currentRoute.startsWith(AdminRoutes.storage),
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 22),
                  _SidebarSection(label: 'Hệ thống', isCollapsed: isCollapsed),
                  _SidebarItem(
                    label: 'App Config',
                    icon: Icons.tune_rounded,
                    routeName: AdminRoutes.appConfig,
                    isActive: currentRoute == AdminRoutes.appConfig,
                    isCollapsed: isCollapsed,
                  ),
                  _SidebarItem(
                    label: 'Gửi thông báo',
                    icon: Icons.notifications_active_outlined,
                    routeName: AdminRoutes.messaging,
                    isActive: currentRoute == AdminRoutes.messaging,
                    isCollapsed: isCollapsed,
                  ),
                  _SidebarItem(
                    label: 'Lịch sử thông báo',
                    icon: Icons.mark_email_read_outlined,
                    routeName: AdminRoutes.notificationHistory,
                    isActive: currentRoute == AdminRoutes.notificationHistory,
                    isCollapsed: isCollapsed,
                  ),
                  _SidebarItem(
                    label: 'Audit Logs',
                    icon: Icons.history_rounded,
                    routeName: AdminRoutes.auditLogs,
                    isActive: currentRoute == AdminRoutes.auditLogs,
                    isCollapsed: isCollapsed,
                  ),
                  _SidebarItem(
                    label: 'System Health',
                    icon: Icons.monitor_heart_outlined,
                    routeName: AdminRoutes.systemHealth,
                    isActive: currentRoute == AdminRoutes.systemHealth,
                    isCollapsed: isCollapsed,
                  ),
                ],
              ),
            ),
            _SidebarFooter(
              authRepository: _authRepository,
              isCollapsed: isCollapsed,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.isCollapsed});

  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isCollapsed ? 18 : 20, 24, 18, 18),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(
              context,
            ).pushReplacementNamed(AdminRoutes.dashboard),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Sidebar._accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Journal Admin',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({required this.label, required this.isCollapsed});

  final String label;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) return const SizedBox(height: 16);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Sidebar._sectionText,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.routeName,
    required this.isActive,
    required this.isCollapsed,
  });

  final String label;
  final IconData icon;
  final String routeName;
  final bool isActive;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? Colors.white : Sidebar._mutedText;

    return Tooltip(
      message: isCollapsed ? label : '',
      waitDuration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isActive
                ? null
                : () {
                    final scaffold = Scaffold.maybeOf(context);
                    if (scaffold?.isDrawerOpen ?? false) {
                      Navigator.of(context).pop();
                    }
                    Navigator.of(context).pushReplacementNamed(routeName);
                  },
            child: Ink(
              decoration: BoxDecoration(
                color: isActive
                    ? Sidebar._accentColor
                    : Colors.white.withValues(alpha: 0.00),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                height: 46,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 0 : 12,
                  ),
                  child: Row(
                    mainAxisAlignment: isCollapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Icon(icon, color: foreground, size: 21),
                      if (!isCollapsed) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 15,
                              fontWeight: isActive
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.authRepository,
    required this.isCollapsed,
  });

  final AuthRepository authRepository;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: authRepository.currentUser,
      stream: authRepository.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final email = user?.email ?? 'admin@example.com';
        final name = user?.displayName ?? email.split('@').first;

        return Container(
          padding: EdgeInsets.all(isCollapsed ? 14 : 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Tooltip(
            message: isCollapsed ? '$name\n$email' : '',
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  child: Text(
                    email.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Sidebar._mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
