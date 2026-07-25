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
    final isMobile = MediaQuery.sizeOf(context).width < 1100;
    final currentRoute =
        ModalRoute.of(context)?.settings.name ?? AdminRoutes.dashboard;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: _buildBackButton(context, isMobile),
        title: Text(title),
        actions: [_buildAuthAction(context), const SizedBox(width: 16)],
      ),
      drawer: isMobile ? Sidebar(currentRoute: currentRoute) : null,
      body: Row(
        children: [
          if (!isMobile) Sidebar(currentRoute: currentRoute),
          Expanded(
            child: Container(
              margin: isMobile
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(right: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: isMobile
                    ? BorderRadius.zero
                    : BorderRadius.circular(12),
                border: isMobile
                    ? null
                    : Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBackButton(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Builder(
        builder: (context) => IconButton(
          tooltip: 'Open menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu_rounded),
        ),
      );
    }

    if (!Navigator.of(context).canPop()) {
      return null;
    }

    return IconButton(
      tooltip: 'Back',
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }

  Widget _buildAuthAction(BuildContext context) {
    return StreamBuilder(
      initialData: _authRepository.currentUser,
      stream: _authRepository.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();

        final displayName = user.displayName ?? 'Admin Account';
        final email = user.email ?? '';
        final avatarText = (displayName.isNotEmpty ? displayName : email)
            .characters
            .first
            .toUpperCase();

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
                      backgroundColor: const Color(
                        0xFF4F46E5,
                      ).withValues(alpha: 0.12),
                      child: Text(
                        avatarText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
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
                'Dang xuat',
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
