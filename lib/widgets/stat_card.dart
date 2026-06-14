import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;

  const StatCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface, // Thẻ màu trắng nổi bật trên nền ứng dụng
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm), // Bo góc 8px
        border: Border.all(
          color: AppColors
              .primaryLight, // Đường viền mỏng đỏ nhẹ tạo sự liên kết tinh tế
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ), // Đổ bóng siêu nhẹ theo chuẩn Heritage
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary, // Chỉ số mang màu nhấn chủ đạo
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
