import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/publication_view_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import 'journals/journals_screen.dart';
import 'home/home_screen.dart';
import 'keywords/keywords_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void _onItemTapped(int index) {
    final controller = context.read<PublicationViewModel>();

    if (index == 1 &&
        controller.journalSources.isEmpty &&
        !controller.isLoadingJournals) {
      controller.searchJournals('');
    }

    controller.setSelectedIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PublicationViewModel>();
    final int selectedIndex = controller.selectedTabIndex;

    final List<Widget> screens = [
      const HomeScreen(),
      const JournalsScreen(),
      const KeywordsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: AppSpacing.borderWidth,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          elevation: 0,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.primary.withValues(alpha: 0.5),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, key: Key('nav_home')),
              activeIcon: Icon(Icons.home, key: Key('nav_home')),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined, key: Key('nav_journals')),
              activeIcon: Icon(Icons.book, key: Key('nav_journals')),
              label: 'Journals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined, key: Key('nav_keywords')),
              activeIcon: Icon(Icons.analytics, key: Key('nav_keywords')),
              label: 'Keywords',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, key: Key('nav_profile')),
              activeIcon: Icon(Icons.person, key: Key('nav_profile')),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
