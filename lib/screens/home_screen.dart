import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import 'search_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Sources';
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Sources', 'icon': Icons.book_outlined},
    {'name': 'Works', 'icon': Icons.article_outlined},
    {'name': 'Authors', 'icon': Icons.person_outline},
    {'name': 'Institutions', 'icon': Icons.account_balance_outlined},
  ];

  void _handleSearch([String? topic]) {
    final searchQuery = (topic ?? _searchController.text).trim();
    
    // Always update the controller's search text to preserve state
    final controller = context.read<PublicationController>();
    controller.updateSearchText(searchQuery);
    controller.updateSearchCategory(_selectedCategory);

    if (searchQuery.isNotEmpty || _selectedCategory == 'Sources') {
      // Lưu vào lịch sử tìm kiếm
      if (searchQuery.isNotEmpty) {
        context.read<UserController>().addSearch(searchQuery);
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultScreen(
            topic: searchQuery, 
            category: _selectedCategory,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập từ khóa tìm kiếm')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize search text and category from controller when returning to screen
    final controller = context.read<PublicationController>();
    final lastSearch = controller.lastSearchText;
    final lastCategory = controller.lastSearchCategory;

    if (_searchController.text.isEmpty && lastSearch.isNotEmpty) {
      _searchController.text = lastSearch;
    }
    
    if (_selectedCategory != lastCategory) {
      setState(() {
        _selectedCategory = lastCategory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Journal Trend Analyzer'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Explore Academic Insights',
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Search across millions of academic works, authors, sources, and institutions from OpenAlex.',
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl * 2),
                
                // Category Selector
                Text('SEARCH CATEGORY', style: AppTextStyles.labelCaps),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['name'];
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(cat['name']),
                          labelStyle: AppTextStyles.labelCaps.copyWith(
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                          avatar: Icon(
                            cat['icon'], 
                            size: 16, 
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.surface,
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? AppColors.accent : AppColors.secondary,
                            width: 1.0,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = cat['name']);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Search Input Field
                AppTextField(
                  controller: _searchController,
                  hintText: _selectedCategory == 'Sources' 
                      ? 'Search academic journals...' 
                      : 'Search for ${_selectedCategory.toLowerCase()}...',
                  prefixIcon: Icons.search,
                  onSubmitted: () => _handleSearch(),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Search Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AppButton(
                    text: 'Search $_selectedCategory',
                    onPressed: () => _handleSearch(),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl * 2),
                Text(
                  'RECENT SEARCHES',
                  style: AppTextStyles.labelCaps,
                ),
                const SizedBox(height: AppSpacing.md),
                
                Consumer<UserController>(
                  builder: (context, userController, child) {
                    final history = userController.recentSearches;
                    
                    if (history.isEmpty) {
                      return Text(
                        'Chưa có lịch sử tìm kiếm.',
                        style: AppTextStyles.bodySmall,
                      );
                    }
                    
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: history.map((topic) => _buildTopicChip(topic)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _handleSearch(label),
      backgroundColor: AppColors.surface,
      labelStyle: AppTextStyles.labelCaps.copyWith(
        color: AppColors.primary,
        fontSize: 11,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.secondary, width: 1.0),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );
  }
}
