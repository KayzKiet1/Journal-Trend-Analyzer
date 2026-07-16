import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../common/firebase_card_decoration.dart';

class FirebaseStatusOverview extends StatelessWidget {
  final List<FirebaseStatusItem> items;

  const FirebaseStatusOverview({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) => _FirebaseStatusTile(item)).toList(),
    );
  }
}

class FirebaseStatusItem {
  const FirebaseStatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isReady,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isReady;
}

class _FirebaseStatusTile extends StatelessWidget {
  final FirebaseStatusItem item;

  const _FirebaseStatusTile(this.item);

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isReady ? AppColors.success : AppColors.secondary;

    return SizedBox(
      width: MediaQuery.of(context).size.width >= 420
          ? (MediaQuery.of(context).size.width -
                    AppSpacing.lg * 2 -
                    AppSpacing.sm) /
                2
          : double.infinity,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: firebaseDemoCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(item.icon, color: statusColor, size: 19),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: AppTextStyles.labelCaps),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
