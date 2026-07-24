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

  /// Xây dựng cụm nút hành động liên quan đến tài khoản (Đăng xuất) chuyên nghiệp hơn.
  Widget _buildAuthAction(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder(
      stream: _authRepository.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const SizedBox.shrink();
        }

        return MenuAnchor(
          style: MenuStyle(
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 8)),
            elevation: WidgetStateProperty.all(8),
          ),
          builder: (context, controller, child) {
            return InkWell(
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hiển thị tên và email ở phía trước Avatar (chỉ trên màn hình lớn).
                    if (MediaQuery.of(context).size.width > 600)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.displayName ?? 'Admin Account',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            user.email ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 12),
                    // Avatar với chữ cái đầu của người dùng.
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        (user.displayName ?? user.email ?? 'A')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            );
          },
          menuChildren: [
            // Header bên trong menu xổ xuống.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tài khoản quản trị',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Nút đăng xuất nổi bật.
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
              leadingIcon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }
}
