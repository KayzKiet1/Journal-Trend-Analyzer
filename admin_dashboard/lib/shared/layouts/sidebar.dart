import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/repositories/auth_repository.dart';

class Sidebar extends StatelessWidget {
  Sidebar({
    required this.currentRoute,
    super.key,
    AuthRepository? authRepository,
  }) : _authRepository = authRepository ?? FirebaseAuthRepository();

  final String currentRoute;
  final AuthRepository _authRepository;

  static const _backgroundColor = Color(0xFF0F172A);
  static const _activeItemColor = Colors.white;
  static const _inactiveItemColor = Color(0xFFCBD5E1);
  static const _categoryColor = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Column(
        children: [
          const _SidebarHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                const _SidebarCategory(label: 'CHÍNH'),
                _SidebarItem(
                  label: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  routeName: AdminRoutes.dashboard,
                  isActive: currentRoute == AdminRoutes.dashboard,
                ),
                _SidebarItem(
                  label: 'Analytics',
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  routeName: AdminRoutes.analytics,
                  isActive: currentRoute == AdminRoutes.analytics,
                ),
                const SizedBox(height: 20),
                const _SidebarCategory(label: 'QUẢN LÝ'),
                _SidebarItem(
                  label: 'Users',
                  icon: Icons.people_alt_outlined,
                  activeIcon: Icons.people_alt,
                  routeName: AdminRoutes.users,
                  isActive: currentRoute.startsWith(AdminRoutes.users),
                ),
                _SidebarItem(
                  label: 'Firestore',
                  icon: Icons.storage_outlined,
                  activeIcon: Icons.storage,
                  routeName: AdminRoutes.firestoreCollections,
                  isActive: currentRoute.startsWith(
                    AdminRoutes.firestoreCollections,
                  ),
                ),
                _SidebarItem(
                  label: 'Storage',
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder,
                  routeName: AdminRoutes.storage,
                  isActive: currentRoute.startsWith(AdminRoutes.storage),
                ),
                const SizedBox(height: 20),
                const _SidebarCategory(label: 'HỆ THỐNG'),
                _SidebarItem(
                  label: 'App Config',
                  icon: Icons.tune_outlined,
                  activeIcon: Icons.tune,
                  routeName: AdminRoutes.appConfig,
                  isActive: currentRoute == AdminRoutes.appConfig,
                ),
                _SidebarItem(
                  label: 'Messaging',
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                  routeName: AdminRoutes.messaging,
                  isActive: currentRoute == AdminRoutes.messaging,
                ),
                _SidebarItem(
                  label: 'Notification History',
                  icon: Icons.mark_email_read_outlined,
                  activeIcon: Icons.mark_email_read,
                  routeName: AdminRoutes.notificationHistory,
                  isActive: currentRoute == AdminRoutes.notificationHistory,
                ),
                _SidebarItem(
                  label: 'Audit Logs',
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  routeName: AdminRoutes.auditLogs,
                  isActive: currentRoute == AdminRoutes.auditLogs,
                ),
                _SidebarItem(
                  label: 'System Health',
                  icon: Icons.monitor_heart_outlined,
                  activeIcon: Icons.monitor_heart,
                  routeName: AdminRoutes.systemHealth,
                  isActive: currentRoute == AdminRoutes.systemHealth,
                ),
              ],
            ),
          ),
          _SidebarFooter(authRepository: _authRepository),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_graph, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Journal Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarCategory extends StatelessWidget {
  const _SidebarCategory({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Sidebar._categoryColor,
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.routeName,
    required this.isActive,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String routeName;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isActive
              ? null
              : () {
                  if (Scaffold.of(context).isDrawerOpen) {
                    Navigator.pop(context);
                  }
                  Navigator.of(context).pushReplacementNamed(routeName);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isActive ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 9),
                Icon(
                  isActive ? activeIcon : icon,
                  size: 22,
                  color: isActive
                      ? Sidebar._activeItemColor
                      : Sidebar._inactiveItemColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Sidebar._activeItemColor
                          : Sidebar._inactiveItemColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: authRepository.currentUser,
      stream: authRepository.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final accountLabel = user?.email ?? 'Admin Account';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF334155),
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  accountLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
