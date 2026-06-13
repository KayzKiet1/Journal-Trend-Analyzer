import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TopJournalList extends StatelessWidget {
  final Map<String, int> journals;

  const TopJournalList({super.key, required this.journals});

  @override
  Widget build(BuildContext context) {
    if (journals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Không có dữ liệu tạp chí."),
      );
    }

    return Column(
      children: journals.entries.map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.menu_book, color: Colors.white, size: 16),
          ),
          title: Text(
            entry.key,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${entry.value} bài',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        );
      }).toList(),
    );
  }
}