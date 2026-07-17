import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

/// Biểu đồ thanh ngang (Horizontal Bar Chart) dùng cho Keywords, Authors, Journals
class HorizontalBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final String labelKey;
  final String valueKey;
  final ValueChanged<Map<String, dynamic>>? onItemTap;

  const HorizontalBarChart({
    super.key,
    required this.data,
    required this.title,
    this.labelKey = 'name',
    this.valueKey = 'count',
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Tìm giá trị lớn nhất để tính toán tỷ lệ thanh
    final int maxValue = data
        .map((e) => (e[valueKey] as num).toInt())
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: AppTextStyles.labelCaps),
        if (onItemTap != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('Tap a row to open details.', style: AppTextStyles.bodySmall),
        ],
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.secondary, width: 1.0),
          ),
          child: Column(
            children: data.map((item) {
              final String label = item[labelKey].toString();
              final int value = (item[valueKey] as num).toInt();
              final double percentage = maxValue > 0 ? value / maxValue : 0;

              final row = Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: onItemTap == null
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: onItemTap == null
                      ? Colors.transparent
                      : AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: onItemTap == null
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          value.toString(),
                          style: AppTextStyles.labelCaps.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                        if (onItemTap != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
              if (onItemTap == null) return row;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  onTap: () => onItemTap!(item),
                  child: Semantics(
                    button: true,
                    label: 'Open details for $label',
                    child: row,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
