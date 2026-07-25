import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/repositories/auth_repository.dart';
import 'sidebar.dart';

class AdminShell extends StatelessWidget {
  AdminShell({required this.title, required this.child, super.key})
    : _authRepository = FirebaseAuthRepository();

  final String title;
  final Widget child;
  final AuthRepository _authRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? AdminRoutes.dashboard;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8FAFC),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            actions: [
              _buildAuthAction(context),
              const SizedBox(width: 16),
            ],
          ),
          drawer: isMobile ? Sidebar(currentRoute: currentRoute) : null,
          body: Row(
            children: [
              if (!isMobile) Sidebar(currentRoute: currentRoute),
              Expanded(
                child: Container(
                  margin: isMobile ? EdgeInsets.zero : const EdgeInsets.only(right: 16, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
                    border: isMobile ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthAction(BuildContext context) {
    return StreamBuilder(
      stream: _authRepository.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();

        return MenuAnchor(
          builder: (context, controller, child) {
            return InkWell(
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                      child: Text(
                        (user.displayName ?? user.email ?? 'A')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
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
                    user.displayName ?? 'Admin Account',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Text(
                    user.email ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            MenuItemButton(
              onPressed: () async {
                await _authRepository.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(AdminRoutes.login, (route) => false);
                }
              },
              leadingIcon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}
