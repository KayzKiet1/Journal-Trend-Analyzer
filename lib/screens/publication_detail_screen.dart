import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/publication_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import 'search_result_screen.dart';

class PublicationDetailScreen extends StatelessWidget {
  final Publication publication;
  const PublicationDetailScreen({super.key, required this.publication});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chi tiết bài báo')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: PublicationDetailView(publication: publication),
        ),
      ),
    );
  }
}

class PublicationDetailView extends StatelessWidget {
  final Publication publication;
  const PublicationDetailView({super.key, required this.publication});

  Future<void> _launchURL(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    await launchUrl(url, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(publication.title, style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.xl),
          _buildInfoRow(Icons.calendar_today, 'Năm xuất bản', publication.publicationYear.toString()),
          _buildInfoRow(Icons.book, 'Tạp chí', publication.journalName),
          _buildInfoRow(Icons.format_quote, 'Lượt trích dẫn', publication.citedByCount.toString()),
          const SizedBox(height: AppSpacing.xl),
          Text('TÓM TẮT (ABSTRACT)', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.md),
          Text(publication.abstractText, style: AppTextStyles.bodyLarge.copyWith(height: 1.6)),
          const SizedBox(height: AppSpacing.xl),
          if (publication.doi.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _launchURL(context, publication.doi),
              icon: const Icon(Icons.open_in_new),
              label: const Text('XEM TOÀN VĂN (DOI)'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
