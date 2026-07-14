import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class PublicationDoiRow extends StatelessWidget {
  final String doi;
  final ValueChanged<String?> onOpenDoi;

  const PublicationDoiRow({
    super.key,
    required this.doi,
    required this.onOpenDoi,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.link, size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall,
                children: [
                  const TextSpan(
                    text: 'DOI: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () => onOpenDoi(doi),
                      child: Text(
                        doi.isEmpty ? 'N/A' : doi,
                        style: TextStyle(
                          color: doi.isNotEmpty
                              ? AppColors.accent
                              : AppColors.primary,
                          decoration: doi.isNotEmpty
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
