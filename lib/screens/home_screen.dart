import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _selectedCategory = 'Works';
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Works', 'icon': Icons.article_outlined},
    {'name': 'Authors', 'icon': Icons.person_outline},
    {'name': 'Sources', 'icon': Icons.book_outlined},
    {'name': 'Institutions', 'icon': Icons.account_balance_outlined},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicationController>().fetchPopularTopics();
    });
  }

  void _handleSearch([String? topic]) {
    final searchQuery = topic ?? _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
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
                ),
                const SizedBox(height: AppSpacing.xl),

                // Search Input Field
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search for ${_selectedCategory.toLowerCase()}...',
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Search Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AppButton(
                    text: 'Search ${_selectedCategory}',
                    onPressed: () => _handleSearch(),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl * 2),
                Text(
                  'POPULAR TOPICS',
                  style: AppTextStyles.labelCaps,
                ),
                const SizedBox(height: AppSpacing.md),
                
                Consumer<PublicationController>(
                  builder: (context, controller, child) {
                    if (controller.isTopicsLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
                      );
                    }
                    
                    final topics = controller.popularTopics;
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: topics.map((topic) => _buildTopicChip(topic)).toList(),
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
      onPressed: () {
        setState(() => _selectedCategory = 'Works');
        _handleSearch(label);
      },
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
