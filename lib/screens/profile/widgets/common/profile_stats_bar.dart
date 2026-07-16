import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class ProfileStatsBar extends StatelessWidget {
  final int savedJournals;
  final int savedPublications;
  final int exportedPdfCount;
  final int notificationCount;

  const ProfileStatsBar({
    super.key,
    required this.savedJournals,
    required this.savedPublications,
    required this.exportedPdfCount,
    required this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _ProfileStat(
        icon: Icons.menu_book_outlined,
        value: savedJournals,
        label: 'Journals',
        color: AppColors.accent,
      ),
      _ProfileStat(
        icon: Icons.article_outlined,
        value: savedPublications,
        label: 'Publications',
        color: AppColors.primarySoft,
      ),
      _ProfileStat(
        icon: Icons.picture_as_pdf_outlined,
        value: exportedPdfCount,
        label: 'PDFs',
        color: AppColors.warning,
      ),
      _ProfileStat(
        icon: Icons.notifications_outlined,
        value: notificationCount,
        label: 'Notifications',
        color: AppColors.success,
      ),
    ];

    return Semantics(
      label:
          '$savedJournals saved journals, $savedPublications saved publications, '
          '$exportedPdfCount PDF exports, $notificationCount notifications',
      child: Container(
        key: const Key('profile_stats_bar'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < stats.length; index++) ...[
              Expanded(child: _ProfileStatTile(stat: stats[index])),
              if (index != stats.length - 1)
                Container(
                  width: 1,
                  height: 58,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  color: AppColors.border,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileStat {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}

class _ProfileStatTile extends StatelessWidget {
  final _ProfileStat stat;

  const _ProfileStatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(stat.icon, color: stat.color, size: 16),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatStatValue(stat.value),
              style: AppTextStyles.h2.copyWith(color: stat.color, fontSize: 20),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                stat.label,
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.secondary,
                  fontSize: 10,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatStatValue(int value) {
  if (value < 1000) return value.toString();
  if (value < 1000000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '${(value / 1000000).toStringAsFixed(1)}M';
}
