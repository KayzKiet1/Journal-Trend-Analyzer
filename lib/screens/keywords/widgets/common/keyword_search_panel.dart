import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../../widgets/app_text_field.dart';

class KeywordSearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String resultQuery;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;

  const KeywordSearchPanel({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.resultQuery,
    required this.onSearch,
    required this.onClear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final searchField = AppTextField(
          fieldKey: const Key('keyword_search_field'),
          controller: controller,
          hintText: 'Search a topic for keyword analysis',
          prefixIcon: Icons.manage_search,
          suffixIcon: controller.text.isEmpty ? null : Icons.close,
          onSuffixTap: onClear,
          onChanged: onChanged,
          onSubmitted: onSearch,
        );
        final searchButton = ElevatedButton.icon(
          key: const Key('keyword_search_button'),
          onPressed: isLoading ? null : onSearch,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search, size: 18),
          label: const Text('Search'),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SEARCH KEYWORD TRENDS', style: AppTextStyles.labelCaps),
                  const SizedBox(height: AppSpacing.sm),
                  if (isCompact)
                    Column(
                      children: [
                        searchField,
                        const SizedBox(height: AppSpacing.sm),
                        Row(children: [Expanded(child: searchButton)]),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: AppSpacing.sm),
                        searchButton,
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _KeywordResultSummary(query: resultQuery),
          ],
        );
      },
    );
  }
}

class _KeywordResultSummary extends StatelessWidget {
  final String query;

  const _KeywordResultSummary({required this.query});

  @override
  Widget build(BuildContext context) {
    final label = query.isEmpty
        ? 'Search terms are independent from Home.'
        : 'Showing keyword analysis for "$query"';

    return Row(
      children: [
        const Icon(Icons.sell_outlined, size: 16, color: AppColors.accent),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
