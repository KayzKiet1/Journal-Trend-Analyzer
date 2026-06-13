import 'package:flutter/material.dart';
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

  void _handleSearch() {
    final topic = _searchController.text.trim();
    if (topic.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultScreen(topic: topic),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Journal Trend Analyzer'),
        // Do AppBarTheme trong app_theme.dart đã cấu hình đầy đủ màu sắc, 
        // chữ TextStyle và centerTitle nên ở đây chúng ta tối giản thuộc tính.
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Analyze Research Trends',
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Enter a topic to explore publications, citations, and research insights from OpenAlex.',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Search Input Field (Đã thay thế bằng AppTextField custom)
            AppTextField(
              controller: _searchController,
              hintText: 'e.g., Artificial Intelligence',
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Search Button (Đã thay thế bằng AppButton custom)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: AppButton(
                text: 'Search Publications',
                onPressed: _handleSearch,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Popular Topics',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildTopicChip('Artificial Intelligence'),
                _buildTopicChip('Software Engineering'),
                _buildTopicChip('Data Science'),
                _buildTopicChip('Cybersecurity'),
                _buildTopicChip('Blockchain'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _searchController.text = label;
        _handleSearch();
      },
      backgroundColor: AppColors.primaryLight,
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
  }
}