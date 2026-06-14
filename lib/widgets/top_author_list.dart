import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

/// Danh sách Top 5 tác giả theo số lượng bài báo
class TopAuthorList extends StatelessWidget {
  final Map<String, int> authors;

  const TopAuthorList({super.key, required this.authors});

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Không có dữ liệu tác giả.", style: AppTextStyles.bodySmall),
      );
    }

    return Column(
      children: authors.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: AppColors.textInverted, size: 16),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  entry.key,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500, 
                    color: AppColors.textPrimary
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${entry.value} bài',
                  style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent, fontSize: 10),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
