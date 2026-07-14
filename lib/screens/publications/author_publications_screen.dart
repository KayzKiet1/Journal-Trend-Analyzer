import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../viewmodels/publication_view_model.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import 'publication_detail_screen.dart';
import 'widgets/author/author_publications_error.dart';
import 'widgets/author/author_publications_list.dart';

class AuthorPublicationsScreen extends StatefulWidget {
  final String authorId;
  final String authorName;

  const AuthorPublicationsScreen({
    super.key,
    required this.authorId,
    required this.authorName,
  });

  @override
  State<AuthorPublicationsScreen> createState() =>
      _AuthorPublicationsScreenState();
}

class _AuthorPublicationsScreenState extends State<AuthorPublicationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicationViewModel>().searchByAuthor(
        widget.authorId,
        widget.authorName,
      );
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }

    final controller = context.read<PublicationViewModel>();
    if (!controller.isLoadingMore && controller.hasMoreFor('AuthorWorks')) {
      controller.searchByAuthor(
        widget.authorId,
        widget.authorName,
        loadMore: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Papers by ${widget.authorName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Consumer<PublicationViewModel>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.publications.isEmpty) {
            return const LoadingWidget(
              message: 'Loading data from OpenAlex...',
            );
          }

          if (controller.errorMessage.isNotEmpty &&
              controller.publications.isEmpty) {
            return AuthorPublicationsError(
              message: controller.errorMessage,
              onRetry: () =>
                  controller.searchByAuthor(widget.authorId, widget.authorName),
            );
          }

          if (controller.publications.isEmpty) {
            return const EmptyStateWidget(message: 'No publications found.');
          }

          return AuthorPublicationsList(
            scrollController: _scrollController,
            publications: controller.publications,
            hasMore: controller.hasMoreFor('AuthorWorks'),
            onPublicationTap: (publication) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PublicationDetailScreen(publication: publication),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
