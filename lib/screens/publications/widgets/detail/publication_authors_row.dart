import 'package:flutter/material.dart';

import '../../../../models/publication_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class PublicationAuthorsRow extends StatelessWidget {
  final Publication publication;
  final void Function(String authorId, String authorName) onAuthorTap;

  const PublicationAuthorsRow({
    super.key,
    required this.publication,
    required this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person, size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Wrap(
              children: [
                Text(
                  'Authors: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...publication.authors.asMap().entries.map((entry) {
                  final author = entry.value;
                  final isLast = entry.key == publication.authors.length - 1;

                  return GestureDetector(
                    onTap: () => onAuthorTap(author.id, author.name),
                    child: Text(
                      '${author.name}${isLast ? "" : ", "}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: author.id.isNotEmpty
                            ? AppColors.accent
                            : AppColors.primary,
                        decoration: author.id.isNotEmpty
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
