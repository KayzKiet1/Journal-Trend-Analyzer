import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/publication_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../viewmodels/publication_detail_view_model.dart';
import 'author_publications_screen.dart';
import 'widgets/detail/publication_detail_content.dart';

class PublicationDetailScreen extends StatefulWidget {
  final Publication publication;

  const PublicationDetailScreen({super.key, required this.publication});

  @override
  State<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  final PublicationDetailViewModel _viewModel = PublicationDetailViewModel();

  Publication get publication => widget.publication;

  @override
  void initState() {
    super.initState();
    _viewModel.logViewPublication(publication);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
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
        builder: (context) => AuthorPublicationsScreen(
          authorId: authorId,
          authorName: authorName,
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
          child: PublicationDetailContent(
            publication: publication,
            onAuthorTap: (authorId, authorName) =>
                _searchByAuthor(context, authorId, authorName),
            onOpenDoi: (doi) => _launchURL(context, doi),
          ),
        ),
      ),
    );
  }
}
