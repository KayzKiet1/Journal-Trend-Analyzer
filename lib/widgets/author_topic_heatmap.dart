import 'package:flutter/material.dart';
import '../models/publication_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

/// Heatmap showing research expertise: top Authors vs top Topics
class AuthorTopicHeatmap extends StatelessWidget {
  final List<Publication> publications;
  final String title;

  const AuthorTopicHeatmap({
    super.key,
    required this.publications,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (publications.isEmpty) return const SizedBox.shrink();

    // 1. Find top 5 authors (excluding 'Unknown Author')
    final authorCounts = <String, int>{};
    for (var pub in publications) {
      for (var author in pub.authors) {
        if (author.name != 'Unknown Author') {
          authorCounts[author.name] = (authorCounts[author.name] ?? 0) + 1;
        }
      }
    }
    final topAuthors = authorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final List<String> targetAuthors = topAuthors.take(5).map((e) => e.key).toList();

    // 2. Find top 5 topics (excluding 'Unknown' and empty)
    final topicCounts = <String, int>{};
    for (var pub in publications) {
      for (var topic in pub.topics) {
        if (topic != 'Unknown' && topic.trim().isNotEmpty) {
          topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
        }
      }
    }
    final topTopics = topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final List<String> targetTopics = topTopics.take(5).map((e) => e.key).toList();

    if (targetAuthors.isEmpty || targetTopics.isEmpty) {
      return const SizedBox.shrink();
    }

    // 3. Compute matrix
    final matrix = <String, Map<String, int>>{};
    for (var author in targetAuthors) {
      matrix[author] = {};
      for (var topic in targetTopics) {
        matrix[author]![topic] = 0;
      }
    }

    for (var pub in publications) {
      for (var author in pub.authors) {
        if (targetAuthors.contains(author.name)) {
          for (var topic in pub.topics) {
            if (targetTopics.contains(topic)) {
              matrix[author.name]![topic] = (matrix[author.name]![topic] ?? 0) + 1;
            }
          }
        }
      }
    }

    // Find max value in matrix for color scaling
    int maxVal = 1;
    for (var author in targetAuthors) {
      for (var topic in targetTopics) {
        final val = matrix[author]![topic] ?? 0;
        if (val > maxVal) maxVal = val;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.secondary.withOpacity(0.3), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heatmap Table
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.8), // Author Column
                  1: FlexColumnWidth(1.0),
                  2: FlexColumnWidth(1.0),
                  3: FlexColumnWidth(1.0),
                  4: FlexColumnWidth(1.0),
                  5: FlexColumnWidth(1.0),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Header Row
                  TableRow(
                    children: [
                      const TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            'Tác giả',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(targetTopics.length, (index) {
                        return TableCell(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                'T${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  
                  // Data Rows
                  ...targetAuthors.map((author) {
                    return TableRow(
                      children: [
                        // Author Name
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                            child: Text(
                              author,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Topic cells
                        ...targetTopics.map((topic) {
                          final count = matrix[author]![topic] ?? 0;
                          
                          // Scale color based on count
                          double opacity = 0.05;
                          if (count > 0) {
                            opacity = 0.15 + (count / maxVal) * 0.85;
                            if (opacity > 1.0) opacity = 1.0;
                          }
                          final cellColor = count > 0 
                              ? AppColors.accent.withOpacity(opacity)
                              : Colors.grey.withOpacity(0.05);

                          return TableCell(
                            child: Container(
                              margin: const EdgeInsets.all(2.0),
                              height: 32,
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  count > 0 ? count.toString() : '-',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                                    color: count > 0 && opacity > 0.5 
                                        ? Colors.white 
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Legend list
              const Divider(color: AppColors.secondary, thickness: 0.3),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Chú giải Chủ đề (Topics Key):',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...List.generate(targetTopics.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'T${index + 1}: ',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          targetTopics[index],
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
