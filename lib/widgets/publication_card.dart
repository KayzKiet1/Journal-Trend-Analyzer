import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

/// Thẻ hiển thị tóm tắt thông tin một bài báo trong danh sách kết quả
class PublicationCard extends StatelessWidget {
  final String title;
  final String year;
  final String journal;
  final String authors;
  final int citations;
  final VoidCallback onTap;
  final bool isSelected;

  const PublicationCard({
    super.key,
    required this.title,
    required this.year,
    required this.journal,
    required this.authors,
    required this.citations,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.secondary,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
// ...
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề bài báo
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Tác giả
            Text(
              authors,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Hàng thông tin phụ: Tạp chí, Số trích dẫn, Năm
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    journal,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                
                // Hiển thị số lượng trích dẫn
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.format_quote, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        '$citations',
                        style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                
                // Năm xuất bản
                Text(
                  year,
                  style: AppTextStyles.labelCaps,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
