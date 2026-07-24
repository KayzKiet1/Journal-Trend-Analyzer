import 'package:flutter/material.dart';
import '../../app/router.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 280,
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
                _SidebarCategory(label: 'MAIN', colorScheme: colorScheme),
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
                const SizedBox(height: 24),
                _SidebarCategory(label: 'MANAGEMENT', colorScheme: colorScheme),
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
                  isActive: currentRoute.startsWith(AdminRoutes.firestoreCollections),
                ),
                _SidebarItem(
                  label: 'Storage',
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder,
                  routeName: AdminRoutes.storage,
                  isActive: currentRoute.startsWith(AdminRoutes.storage),
                ),
                const SizedBox(height: 24),
                _SidebarCategory(label: 'SYSTEM', colorScheme: colorScheme),
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
                  label: 'Audit Logs',
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  routeName: AdminRoutes.auditLogs,
                  isActive: currentRoute == AdminRoutes.auditLogs,
                ),
              ],
            ),
          ),
          _SidebarFooter(colorScheme: colorScheme),
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
      padding: const EdgeInsets.all(24),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(Icons.auto_graph, color: colorScheme.primary, size: 32),
          const SizedBox(width: 12),
          Text(
            'Journal Admin',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
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
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
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
        borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 22,
                  color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
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
  const _SidebarFooter({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.secondaryContainer,
            child: Icon(Icons.person, size: 18, color: colorScheme.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Admin Account',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
