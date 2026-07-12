import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../firebase/firebase_analytics_service.dart';
import '../models/publication_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import 'search_result_screen.dart';

class PublicationDetailScreen extends StatefulWidget {
  final Publication publication;

  const PublicationDetailScreen({super.key, required this.publication});

  @override
  State<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  final FirebaseAnalyticsService _analyticsService = FirebaseAnalyticsService();

  Publication get publication => widget.publication;

  @override
  void initState() {
    super.initState();
    _analyticsService.logViewPublication(
      publicationTitle: publication.title,
      publicationYear: publication.publicationYear,
    );
  }

  Future<void> _launchURL(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.secondary, width: 1.0),
        ),
        title: Text('Open external link?', style: AppTextStyles.h2),
        content: Text(
          'Do you want to leave the app and open the publication in a browser?',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'OPEN',
              style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final Uri url = Uri.parse(urlString);
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.platformDefault,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error while opening the browser.')),
        );
      }
    }
  }

  void _searchByAuthor(
    BuildContext context,
    String authorId,
    String authorName,
  ) {
    if (authorId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(
          topic: authorName,
          category: 'AuthorWorks',
          authorId: authorId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Publication Details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              key: const Key('publication_detail_content'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(publication.title, style: AppTextStyles.h1),
                const SizedBox(height: AppSpacing.xl),

                _buildClickableAuthors(context),

                _buildInfoRow(
                  Icons.calendar_today,
                  'Publication year',
                  publication.publicationYear.toString(),
                ),
                _buildInfoRow(Icons.book, 'Journal', publication.journalName),
                _buildInfoRow(
                  Icons.format_quote,
                  'Citations',
                  publication.citedByCount.toString(),
                ),

                _buildClickableDOI(context),

                const SizedBox(height: AppSpacing.xl * 2),

                Text('ABSTRACT', style: AppTextStyles.labelCaps),
                const SizedBox(height: AppSpacing.md),
                Text(
                  publication.abstractText,
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                ),
                const SizedBox(height: AppSpacing.xl * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClickableAuthors(BuildContext context) {
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
                    onTap: () =>
                        _searchByAuthor(context, author.id, author.name),
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

  Widget _buildClickableDOI(BuildContext context) {
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
                      onTap: () => _launchURL(context, publication.doi),
                      child: Text(
                        publication.doi.isEmpty ? 'N/A' : publication.doi,
                        style: TextStyle(
                          color: publication.doi.isNotEmpty
                              ? AppColors.accent
                              : AppColors.primary,
                          decoration: publication.doi.isNotEmpty
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: value.isEmpty ? 'N/A' : value,
                    style: const TextStyle(color: AppColors.primary),
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
