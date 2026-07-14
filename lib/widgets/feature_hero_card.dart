import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

class FeatureHeroCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final List<String> badges;

  const FeatureHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    this.badges = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primarySoft, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -22,
            child: Icon(
              icon,
              size: 112,
              color: AppColors.surface.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.surface.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  eyebrow,
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.88),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.surface,
                  fontSize: 24,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.surface.withValues(alpha: 0.86),
                  height: 1.45,
                ),
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: badges
                      .map((label) => _FeatureHeroBadge(label: label))
                      .toList(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureHeroBadge extends StatelessWidget {
  final String label;

  const _FeatureHeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelCaps.copyWith(
          color: AppColors.surface.withValues(alpha: 0.9),
          fontSize: 10,
        ),
      ),
    );
  }
}
