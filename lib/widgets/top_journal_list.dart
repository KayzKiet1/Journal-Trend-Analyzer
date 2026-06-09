import 'package:flutter/material.dart';

import '../models/publication_model.dart';
import '../utils/analysis_helper.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

/// Danh sách Top 5 tạp chí theo số lượng bài báo
class TopJournalList extends StatelessWidget {
  final List<Publication> publications;
  final String title;

  const TopJournalList({
    super.key,
    required this.publications,
    this.title = 'Tạp chí xuất bản nhiều nhất',
  });

  @override
  Widget build(BuildContext context) {
    final topJournals = AnalysisHelper.getTopJournals(publications);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.sm),
        if (topJournals.isEmpty)
          _buildEmptyState(
            publications.isEmpty
                ? 'Chưa có bài báo để phân tích tạp chí.'
                : 'Không có dữ liệu tạp chí hợp lệ để hiển thị.',
          )
        else
          ...topJournals.entries.toList().asMap().entries.map(
                (entry) => _buildRankedItem(
                  rank: entry.key + 1,
                  title: entry.value.key,
                  subtitle: '${entry.value.value} bài báo',
                ),
              ),
      ],
    );
  }

  Widget _buildRankedItem({
    required int rank,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accent,
            child: Text(
              '$rank',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textInverted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 40,
            color: AppColors.secondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
