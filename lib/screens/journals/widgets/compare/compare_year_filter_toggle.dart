import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class CompareYearFilterToggle extends StatelessWidget {
  final int currentYear;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CompareYearFilterToggle({
    super.key,
    required this.currentYear,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        dense: true,
        contentPadding: EdgeInsets.zero,
        activeThumbColor: AppColors.accent,
        title: Text(
          'Chỉ tính đến năm hiện tại ($currentYear)',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Bật để bỏ qua các năm bất thường trong tương lai như 8121 hoặc 9999 khi so sánh.',
          style: AppTextStyles.bodySmall,
        ),
      ),
    );
  }
}
