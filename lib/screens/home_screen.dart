import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/adaptive_layout_wrapper.dart';
import 'search_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Works';
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Works', 'icon': Icons.article_outlined},
    {'name': 'Authors', 'icon': Icons.person_outline},
    {'name': 'Sources', 'icon': Icons.book_outlined},
    {'name': 'Institutions', 'icon': Icons.account_balance_outlined},
  ];

  void _handleSearch([String? topic]) {
    final searchQuery = topic ?? _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      context.read<UserController>().addSearch(searchQuery);
<<<<<<< Updated upstream
      
=======
>>>>>>> Stashed changes
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultScreen(
            topic: searchQuery, 
            category: _selectedCategory,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayoutWrapper(
      title: 'Explore Academic Insights',
      currentRoute: 'home',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search across millions of academic data from OpenAlex.', style: AppTextStyles.bodyLarge),
                const SizedBox(height: AppSpacing.xl),
                
                // M3 Chips
                Text('SEARCH CATEGORY', style: AppTextStyles.labelCaps),
                const SizedBox(height: AppSpacing.md),
<<<<<<< Updated upstream
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(cat['name']),
                        avatar: Icon(
                          cat['icon'], 
                          size: 16, 
                          color: _selectedCategory == cat['name'] 
                            ? AppColors.textInverted 
                            : AppColors.primary,
                        ),
                        selected: _selectedCategory == cat['name'],
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = cat['name']);
                        },
                      ),
                    )).toList(),
                  ),
=======
                Wrap(
                  spacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['name'];
                    return ChoiceChip(
                      label: Text(cat['name']),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedCategory = cat['name']),
                    );
                  }).toList(),
>>>>>>> Stashed changes
                ),
                
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search for ${_selectedCategory.toLowerCase()}...',
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AppButton(
                    text: 'Search $_selectedCategory',
                    onPressed: () => _handleSearch(),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl * 2),
                Text('RECENT SEARCHES', style: AppTextStyles.labelCaps),
                const SizedBox(height: AppSpacing.md),
                Consumer<UserController>(
                  builder: (context, user, _) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.recentSearches.map((topic) => ActionChip(
                      label: Text(topic),
                      onPressed: () => _handleSearch(topic),
                    )).toList(),
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
