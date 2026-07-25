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
  static const _accentColor = Color(0xFF6366F1);
  static const _inactiveColor = Color(0xFF94A3B8);
  static const _categoryColor = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
      ),
      child: Column(
        children: [
          const _SidebarHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              children: [
                const _SidebarCategory(label: 'MENU CHÍNH', key: ValueKey('cat_main')),
                _SidebarItem(
                  key: const ValueKey('nav_dashboard'),
                  label: 'Dashboard',
                  icon: Icons.grid_view_rounded,
                  routeName: AdminRoutes.dashboard,
                  isActive: currentRoute == AdminRoutes.dashboard,
                ),
                _SidebarItem(
                  key: const ValueKey('nav_analytics'),
                  label: 'Phân tích (Analytics)',
                  icon: Icons.bar_chart_rounded,
                  routeName: AdminRoutes.analytics,
                  isActive: currentRoute == AdminRoutes.analytics,
                ),
                const SizedBox(height: 32),
                const _SidebarCategory(label: 'QUẢN LÝ DỮ LIỆU', key: ValueKey('cat_mgmt')),
                _SidebarItem(
                  key: const ValueKey('nav_users'),
                  label: 'Người dùng',
                  icon: Icons.people_outline_rounded,
                  routeName: AdminRoutes.users,
                  isActive: currentRoute.startsWith(AdminRoutes.users),
                ),
                _SidebarItem(
                  key: const ValueKey('nav_firestore'),
                  label: 'Firestore Collections',
                  icon: Icons.dns_outlined,
                  routeName: AdminRoutes.firestoreCollections,
                  isActive: currentRoute.startsWith(AdminRoutes.firestoreCollections),
                ),
                _SidebarItem(
                  key: const ValueKey('nav_storage'),
                  label: 'Cloud Storage',
                  icon: Icons.folder_open_rounded,
                  routeName: AdminRoutes.storage,
                  isActive: currentRoute.startsWith(AdminRoutes.storage),
                ),
                const SizedBox(height: 32),
                const _SidebarCategory(label: 'HỆ THỐNG', key: ValueKey('cat_sys')),
                _SidebarItem(
                  key: const ValueKey('nav_config'),
                  label: 'Cấu hình App',
                  icon: Icons.tune_rounded,
                  routeName: AdminRoutes.appConfig,
                  isActive: currentRoute == AdminRoutes.appConfig,
                ),
                _SidebarItem(
                  key: const ValueKey('nav_msg'),
                  label: 'Gửi Thông báo',
                  icon: Icons.send_and_archive_outlined,
                  routeName: AdminRoutes.messaging,
                  isActive: currentRoute == AdminRoutes.messaging,
                ),
                _SidebarItem(
                  key: const ValueKey('nav_audit'),
                  label: 'Lịch sử Audit',
                  icon: Icons.history_rounded,
                  routeName: AdminRoutes.auditLogs,
                  isActive: currentRoute == AdminRoutes.auditLogs,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Sidebar._accentColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Sidebar._accentColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Journal Admin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarCategory extends StatelessWidget {
  const _SidebarCategory({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          color: Sidebar._categoryColor,
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.routeName,
    required this.isActive,
    super.key,
  });

  final String label;
  final IconData icon;
  final String routeName;
  final bool isActive;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: widget.isActive 
              ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)])
              : null,
            color: !widget.isActive && _isHovered ? Colors.white.withOpacity(0.05) : Colors.transparent,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.isActive
                  ? null
                  : () => Navigator.of(context).pushReplacementNamed(widget.routeName),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      size: 22,
                      color: widget.isActive ? Colors.white : Sidebar._inactiveColor,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w600,
                          color: widget.isActive ? Colors.white : Sidebar._inactiveColor,
                        ),
                      ),
                    ),
                  ],
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
  const _SidebarFooter({required this.authRepository});
  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: authRepository.currentUser,
      stream: authRepository.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final email = user?.email ?? 'admin@example.com';

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF1E293B),
                  child: Text(
                    email[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email.split('@').first,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Super Admin',
                      style: TextStyle(fontSize: 11, color: Sidebar._inactiveColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
