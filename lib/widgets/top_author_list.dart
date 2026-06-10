import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TopAuthorList extends StatelessWidget {
  final Map<String, int> authors;

  const TopAuthorList({super.key, required this.authors});

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Không có dữ liệu tác giả."),
      );
    }

    return Column(
      children: authors.entries.map((entry) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFB8422E), // Boston Clay làm điểm nhấn nhẹ
            child: Icon(Icons.person, color: Colors.white, size: 16),
          ),
          title: Text(
            entry.key,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
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