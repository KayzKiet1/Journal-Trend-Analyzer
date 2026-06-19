import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'app_drawer.dart';

class AdaptiveLayoutWrapper extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String title;
  final List<Widget>? actions;
  final bool isSubPage;

  const AdaptiveLayoutWrapper({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.title,
    this.actions,
    this.isSubPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    // Phân loại thiết bị theo Material 3
    final bool isCompact = width < 600; // Mobile
    final bool isMedium = width >= 600 && width < 1240; // Tablet
    final bool isExpanded = width >= 1240; // Desktop

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isExpanded ? null : AppBar(
        title: Text(title),
        actions: actions,
        elevation: 0,
        centerTitle: isCompact,
        // Nếu là trang con, AppBar sẽ tự hiện nút Back nếu drawer là null
      ),
      // Drawer chỉ xuất hiện ở Mobile và KHÔNG PHẢI trang con
      drawer: (isCompact && !isSubPage) ? AppDrawer(currentRoute: currentRoute) : null,
      body: Row(
        children: [
          // M3 Navigation Rail cho Tablet (Medium)
          if (isMedium)
            _buildNavigationRail(context),
          
          // M3 Permanent Navigation Drawer cho Desktop (Expanded)
          if (isExpanded)
            _buildPermanentDrawer(context),

          // Nội dung chính
          Expanded(
            child: Column(
              children: [
                if (isExpanded) _buildDesktopHeader(context),
                Expanded(
                  child: ClipRRect(
                    // Bo góc nội dung chính theo chuẩn M3 khi ở màn hình lớn
                    borderRadius: isCompact ? BorderRadius.zero : const BorderRadius.only(topLeft: Radius.circular(24)),
                    child: Container(
                      color: AppColors.surface,
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      color: AppColors.background,
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          )),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _getSelectedIndex(),
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.accent.withValues(alpha: 0.2),
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (index) => _handleNavigation(context, index),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('HOME')),
        NavigationRailDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: Text('JOURNAL')),
        NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('KEYWORDS')),
        NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('PROFILE')),
      ],
    );
  }

  Widget _buildPermanentDrawer(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.background,
      child: AppDrawer(currentRoute: currentRoute, isPermanent: true),
    );
  }

  int _getSelectedIndex() {
    switch (currentRoute) {
      case 'home': return 0;
      case 'journal': return 1;
      case 'keywords': return 2;
      case 'profile': return 3;
      default: return 0;
    }
  }

  void _handleNavigation(BuildContext context, int index) {
    // Logic điều hướng tương tự như trong AppDrawer
  }
}
