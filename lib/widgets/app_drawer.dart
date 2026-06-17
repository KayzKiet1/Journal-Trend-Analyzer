import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../screens/home_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_result_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();

    return Drawer(
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppSpacing.radiusMd),
          bottomRight: Radius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(userController),
          const SizedBox(height: AppSpacing.md),
          _buildMenuItem(
            context,
            icon: Icons.home_outlined,
            label: 'HOME',
            route: 'home',
            onTap: () => _navigate(context, const HomeScreen()),
          ),
          _buildMenuItem(
            context,
            icon: Icons.book_outlined,
            label: 'JOURNAL',
            route: 'journal',
            onTap: () {
              // Lấy từ khóa tìm kiếm gần nhất, nếu không có thì mặc định là 'AI'
              final lastSearch = userController.recentSearches.isNotEmpty 
                  ? userController.recentSearches.first 
                  : 'AI';
              
              _navigate(context, SearchResultScreen(
                topic: lastSearch,
                category: 'Works',
              ));
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.analytics_outlined,
            label: 'KEYWORDS',
            route: 'keywords',
            onTap: () {
              // Giữ Dashboard cho phần Keywords/Phân tích
              _navigate(context, const DashboardScreen(route: 'keywords'));
            },
          ),
          const Spacer(),
          const Divider(color: AppColors.secondary, thickness: 0.5, indent: 20, endIndent: 20),
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            label: 'PROFILE',
            route: 'profile',
            onTap: () => _navigate(context, const ProfileScreen()),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildHeader(UserController user) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      color: AppColors.primary,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.accent,
            child: Icon(Icons.auto_stories, color: Colors.white, size: 30),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Journal Analyzer',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
          Text(
            user.hasEmail ? user.email : 'Chưa thiết lập Email',
            style: AppTextStyles.labelCaps.copyWith(color: AppColors.background.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required VoidCallback onTap,
  }) {
    final isSelected = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      child: ListTile(
        onTap: isSelected ? () => Navigator.pop(context) : onTap,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.accent : AppColors.primary,
        ),
        title: Text(
          label,
          style: AppTextStyles.labelCaps.copyWith(
            color: isSelected ? AppColors.accent : AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        selectedTileColor: AppColors.accent.withValues(alpha: 0.05),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
