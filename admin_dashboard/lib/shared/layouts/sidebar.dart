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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          _SidebarHeader(colorScheme: colorScheme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _SidebarCategory(label: 'CHÍNH', colorScheme: colorScheme),
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
                _SidebarCategory(label: 'QUẢN LÝ', colorScheme: colorScheme),
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
                _SidebarCategory(label: 'HỆ THỐNG', colorScheme: colorScheme),
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
          _SidebarFooter(
            colorScheme: colorScheme,
            authRepository: _authRepository,
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.auto_graph, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Journal Admin',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
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
  const _SidebarCategory({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.outline,
          letterSpacing: 0,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive ? colorScheme.primaryContainer : Colors.transparent,
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
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
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
  const _SidebarFooter({
    required this.colorScheme,
    required this.authRepository,
  });

  final ColorScheme colorScheme;
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
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            border: Border(
              top: BorderSide(color: colorScheme.outlineVariant, width: 1),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  accountLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
