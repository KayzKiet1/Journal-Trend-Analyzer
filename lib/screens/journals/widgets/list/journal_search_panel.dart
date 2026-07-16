import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../../widgets/app_text_field.dart';

class JournalSearchPanel extends StatelessWidget {
  final TextEditingController textController;
  final bool isLoading;
  final String resultQuery;
  final int resultTotal;
  final int resultLoaded;
  final VoidCallback onClear;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChanged;

  const JournalSearchPanel({
    super.key,
    required this.textController,
    required this.isLoading,
    required this.resultQuery,
    required this.resultTotal,
    required this.resultLoaded,
    required this.onClear,
    required this.onSubmit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;
          final searchField = AppTextField(
            fieldKey: const Key('journal_search_field'),
            controller: textController,
            hintText: 'Search by journal name or publisher',
            prefixIcon: Icons.manage_search,
            suffixIcon: textController.text.isEmpty ? null : Icons.close,
            onSuffixTap: onClear,
            onChanged: onChanged,
            onSubmitted: onSubmit,
          );
          final searchButton = ElevatedButton.icon(
            key: const Key('journal_search_button'),
            onPressed: isLoading ? null : onSubmit,
            icon: const Icon(Icons.search, size: 18),
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
                    Text(
                      'SEARCH JOURNAL SOURCES',
                      style: AppTextStyles.labelCaps,
                    ),
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
              JournalResultSummary(
                query: resultQuery,
                total: resultTotal,
                loaded: resultLoaded,
              ),
            ],
          );
        },
      ),
    );
  }
}

class JournalResultSummary extends StatelessWidget {
  final String query;
  final int total;
  final int loaded;

  const JournalResultSummary({
    super.key,
    required this.query,
    required this.total,
    required this.loaded,
  });

  @override
  Widget build(BuildContext context) {
    final label = query.isEmpty
        ? 'Showing popular journal sources'
        : 'Showing results for "$query"';

    return Row(
      children: [
        const Icon(
          Icons.library_books_outlined,
          size: 16,
          color: AppColors.accent,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            total > 0 ? '$label • $loaded of $total loaded' : label,
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
