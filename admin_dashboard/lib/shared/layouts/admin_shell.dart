import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/repositories/auth_repository.dart';
import 'sidebar.dart';

/// Lớp vỏ bọc giao diện Admin (Shell).
/// Cung cấp cấu trúc điều hướng thống nhất cho toàn bộ hệ thống quản trị,
/// bao gồm Sidebar trên màn hình rộng và Drawer trên màn hình nhỏ.
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
    
    // Lấy tên route hiện tại để làm nổi bật mục tương ứng trong Sidebar.
    final currentRoute = ModalRoute.of(context)?.settings.name ?? AdminRoutes.dashboard;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Xác định xem có nên dùng giao diện Mobile (dưới 900px) hay không.
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            elevation: 0,
            scrolledUnderElevation: 2,
            centerTitle: false,
            // Header chỉ hiện màu nền trên mobile để đồng bộ với thanh AppBar.
            backgroundColor: isMobile ? colorScheme.surface : Colors.transparent,
            actions: [
              _buildAuthAction(context),
              const SizedBox(width: 8),
            ],
          ),
          // Chỉ hiển thị Drawer nếu là màn hình nhỏ.
          drawer: isMobile ? Sidebar(currentRoute: currentRoute) : null,
          body: Row(
            children: [
              // Hiển thị Sidebar cố định trên màn hình rộng.
              if (!isMobile) Sidebar(currentRoute: currentRoute),
              Expanded(
                child: ClipRRect(
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Xây dựng cụm nút hành động liên quan đến tài khoản (Sign out).
  Widget _buildAuthAction(BuildContext context) {
    return StreamBuilder(
      stream: _authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return const SizedBox.shrink();
        }

        return MenuAnchor(
          builder: (context, controller, child) {
            return IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 20),
              ),
            );
          },
          menuChildren: [
            MenuItemButton(
              onPressed: () async {
                await _authRepository.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AdminRoutes.login,
                    (route) => false,
                  );
                }
              },
              leadingIcon: const Icon(Icons.logout, size: 18),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}
