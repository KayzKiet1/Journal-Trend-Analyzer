import 'package:flutter/material.dart';
import '../models/publication_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

/// Màn hình hiển thị thông tin chi tiết của một bài báo
class PublicationDetailScreen extends StatelessWidget {
  final Publication publication;

  const PublicationDetailScreen({super.key, required this.publication});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết bài báo', style: TextStyle(color: AppColors.textInverted)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textInverted),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề bài báo
            Text(
              publication.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Các thông tin cơ bản
            _buildInfoRow(Icons.person, 'Tác giả', publication.authorsString),
            _buildInfoRow(Icons.calendar_today, 'Năm xuất bản', publication.publicationYear.toString()),
            _buildInfoRow(Icons.book, 'Tạp chí', publication.journalName),
            _buildInfoRow(Icons.format_quote, 'Lượt trích dẫn', publication.citedByCount.toString()),
            _buildInfoRow(Icons.link, 'DOI', publication.doi),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Phần tóm tắt (Abstract)
            const Text(
              'Tóm tắt (Abstract)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              publication.abstractText,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// Widget phụ trợ để hiển thị một dòng thông tin có icon
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: value.isEmpty ? 'N/A' : value,
                    style: const TextStyle(color: AppColors.textPrimary),
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
