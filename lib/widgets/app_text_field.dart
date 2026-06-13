// TODO: Implement AppTextField - Assigned to Person 1
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const AppTextField({
    super.key, 
    required this.controller, 
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16.0,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14.0,
        ),
        fillColor: AppColors.surface, // Màu trắng tinh nổi bật trên nền Warm Limestone
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, // 16.0
          vertical: 14.0,
        ),
        
        // Trạng thái viền bình thường
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm), // Bo góc cứng cáp 8.0
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.0),
        ),
        
        // Trạng thái viền khi đang focus (Gõ chữ)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0), // Viền đỏ gạch Boston Clay dày 2px
        ),
        
        // Trạng thái viền khi lỗi (Nếu sau này cần tích hợp validator)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
      ),
    );
  }
}