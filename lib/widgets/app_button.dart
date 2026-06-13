// TODO: Implement AppButton - Assigned to Person 1
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Hỗ trợ thêm trạng thái disabled khi truyền null

  const AppButton({
    super.key, 
    required this.text, 
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        // Màu nền chính là Boston Clay (#B8422E)
        backgroundColor: AppColors.primary,
        // Màu hiệu ứng gợn sóng khi nhấn (Ripple Effect)
        foregroundColor: AppColors.textInverted,
        // Màu sắc khi nút rơi vào trạng thái disabled (onPressed == null)
        disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.2),
        disabledForegroundColor: AppColors.secondary.withValues(alpha: 0.5),
        // Cấu hình khoảng đệm (padding) bên trong nút bấm
        padding: const EdgeInsets.all(AppSpacing.md),
        // Bo góc đồng bộ 8px theo quy chuẩn nghiêm ngặt của dự án
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        // Loại bỏ độ cao/đổ bóng theo nguyên tắc tối giản kiến trúc của Heritage
        elevation: 0,
      ),
      child: Text(
        text,
        // Áp dụng kiểu chữ chuẩn 16px, Semi-Bold, màu trắng tinh hệ thống
        style: AppTextStyles.buttonText,
      ),
    );
  }
}