import 'package:flutter/material.dart';

import '../../../../models/journal_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import 'journal_detail_formatters.dart';
import 'journal_detail_section_card.dart';

class JournalDetailMetadataCard extends StatelessWidget {
  final Journal? journal;
  final ValueChanged<String?> onOpenLink;

  const JournalDetailMetadataCard({
    super.key,
    required this.journal,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    return JournalDetailSectionCard(
      title: 'Journal Metadata',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IDENTITY', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(label: 'Publisher', value: journal?.publisher),
          _InfoRow(label: 'Source type', value: journal?.type),
          _InfoRow(label: 'ISSNs', value: journal?.issns.join(', ')),
          _InfoRow(
            label: 'Alternate names',
            value: journal?.alternateNames.join(', '),
          ),
          const Divider(height: AppSpacing.xl),
          Text('ACCESS', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            label: 'Homepage',
            value: journal?.homepageUrl,
            isLink: true,
            onOpenLink: onOpenLink,
          ),
          _InfoRow(label: 'Fully open access', value: yesNo(journal?.isOa)),
          _InfoRow(label: 'Indexed in DOAJ', value: yesNo(journal?.isInDoaj)),
          _InfoRow(
            label: 'Article processing charge',
            value: journal?.apcUsd != null ? '\$${journal!.apcUsd}' : null,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isLink;
  final ValueChanged<String?>? onOpenLink;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLink = false,
    this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: isLink ? () => onOpenLink?.call(value) : null,
            child: Text(
              value!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isLink ? AppColors.accent : AppColors.primary,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
