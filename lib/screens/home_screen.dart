import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _handleSearch([String? topic]) {
    final searchQuery = (topic ?? _searchController.text).trim();

    // Always update the controller's search text to preserve state
    final controller = context.read<PublicationController>();
    controller.updateSearchText(searchQuery);
    controller.updateSearchCategory('Sources');

    // Chuyển sang Tab Journal (index 1) trong MainScreen
    controller.setSelectedIndex(1);

    // Lưu vào lịch sử tìm kiếm nếu có từ khóa
    if (searchQuery.isNotEmpty) {
      context.read<UserController>().addSearch(searchQuery);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize search text and category from controller when returning to screen
    final controller = context.read<PublicationController>();
    final lastSearch = controller.lastSearchText;

    if (_searchController.text.isEmpty && lastSearch.isNotEmpty) {
      _searchController.text = lastSearch;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Journal Trend Analyzer'), elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Text('Explore Academic Insights', style: AppTextStyles.h1),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Search academic journals from OpenAlex and explore publication trends.',
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl * 2),

                // Search Input Field
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search academic journals...',
                  prefixIcon: Icons.search,
                  onSubmitted: () => _handleSearch(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Search Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AppButton(
                    text: 'Search Journals',
                    onPressed: () => _handleSearch(),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl * 2),
                Text('RECENT SEARCHES', style: AppTextStyles.labelCaps),
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
                      children: history
                          .map((topic) => _buildTopicChip(topic))
                          .toList(),
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
