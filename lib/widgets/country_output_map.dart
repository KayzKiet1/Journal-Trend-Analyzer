import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

/// Hiển thị sản lượng nghiên cứu theo quốc gia dưới dạng danh sách/biểu đồ (Thay cho Map phức tạp)
/// Theo Heritage Design System, ưu tiên sự rõ ràng của dữ liệu
class CountryOutputList extends StatelessWidget {
  final List<Map<String, dynamic>> countries;

  const CountryOutputList({super.key, required this.countries});

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SẢN LƯỢNG NGHIÊN CỨU THEO QUỐC GIA', style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.secondary, width: 1.0),
          ),
          child: Column(
            children: countries.take(5).map((country) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        country['country_code'] ?? '??',
                        style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        '${country['name']} (${country['country_code']})',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      '${country['count']} ấn phẩm',
                      style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
