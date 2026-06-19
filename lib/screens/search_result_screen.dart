import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/publication_controller.dart';
import '../models/publication_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
<<<<<<< Updated upstream
=======
import '../widgets/adaptive_layout_wrapper.dart';
>>>>>>> Stashed changes
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String topic;
  final String category;
  final String? authorId;

  const SearchResultScreen({
    super.key, 
    required this.topic, 
    this.category = 'Works',
    this.authorId,
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final ScrollController _scrollController = ScrollController();
  Publication? _selectedPublication;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.category == 'AuthorWorks' && widget.authorId != null) {
        context.read<PublicationController>().searchByAuthor(widget.authorId!, widget.topic);
      } else {
        context.read<PublicationController>().search(widget.topic, widget.category);
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final controller = context.read<PublicationController>();
      if (!controller.isLoadingMore && controller.hasMore) {
        if (widget.category == 'AuthorWorks' && widget.authorId != null) {
          controller.searchByAuthor(widget.authorId!, widget.topic, loadMore: true);
        } else if (widget.category == 'Works' || widget.category == 'Authors') {
          controller.search(widget.topic, widget.category, loadMore: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = widget.topic;
    if (widget.category == 'AuthorWorks') {
      displayTitle = 'Bài báo của ${widget.topic}';
    } else {
      displayTitle = '${widget.category}: ${widget.topic}';
    }

<<<<<<< Updated upstream
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(displayTitle),
        actions: [
          if (widget.category == 'Works')
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrendAnalysisScreen(topic: widget.topic),
                  ),
                );
              },
              tooltip: 'Trend Analysis',
            ),
        ],
      ),
      body: Consumer<PublicationController>(
=======
    final width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 1000;

    return AdaptiveLayoutWrapper(
      title: displayTitle,
      currentRoute: widget.category == 'Sources' ? 'journal' : '',
      isSubPage: isSubPage,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false),
        ),
        if (widget.category == 'Works')
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrendAnalysisScreen(topic: widget.topic))),
          ),
      ],
      child: Consumer<PublicationController>(
>>>>>>> Stashed changes
        builder: (context, controller, child) {
          if (controller.isLoading && controller.publications.isEmpty && controller.authors.isEmpty && controller.sources.isEmpty) {
            return const LoadingWidget();
          }

          if (isLargeScreen && (widget.category == 'Works' || widget.category == 'AuthorWorks')) {
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildResultList(controller),
                ),
                const VerticalDivider(width: 1, color: AppColors.secondary),
                Expanded(
                  flex: 3,
                  child: _selectedPublication == null
                      ? const Center(child: Text('Chọn một bài báo để xem chi tiết'))
                      : PublicationDetailView(publication: _selectedPublication!),
                ),
              ],
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildResultList(controller),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultList(PublicationController controller) {
    switch (widget.category) {
      case 'Works':
      case 'AuthorWorks':
        if (controller.publications.isEmpty && !controller.isLoading) {
          return const EmptyStateWidget(message: 'Không tìm thấy bài báo nào.');
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.publications.length + (controller.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.publications.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final pub = controller.publications[index];
            final isSelected = _selectedPublication?.id == pub.id;

            return PublicationCard(
              title: pub.title,
              authors: pub.authorsString,
              journal: pub.journalName,
              year: pub.publicationYear.toString(),
              citations: pub.citedByCount,
              isSelected: isSelected,
              onTap: () {
                final width = MediaQuery.of(context).size.width;
                if (width > 1000) {
                  setState(() => _selectedPublication = pub);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicationDetailScreen(publication: pub),
                    ),
                  );
                }
              },
            );
          },
        );

      case 'Authors':
        if (controller.authors.isEmpty && !controller.isLoading) {
          return const EmptyStateWidget(message: 'Không tìm thấy tác giả nào.');
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.authors.length + (controller.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.authors.length) {
              return const Center(child: CircularProgressIndicator());
            }

            final author = controller.authors[index];
            return _buildEntityCard(
              title: author.name,
              subtitle: author.lastKnownInstitution ?? 'Không có thông tin tổ chức',
              trailing: '${author.worksCount} bài báo',
              icon: Icons.person_outline,
              meta: '${author.citedByCount} trích dẫn',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchResultScreen(
                      topic: author.name,
                      category: 'AuthorWorks',
                      authorId: author.id,
                    ),
                  ),
                );
              },
            );
          },
        );

      case 'Sources':
        if (controller.sources.isEmpty && !controller.isLoading) {
          return const EmptyStateWidget(message: 'Không tìm thấy tạp chí nào.');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.sources.length,
          itemBuilder: (context, index) {
            final source = controller.sources[index];
            return _buildEntityCard(
              title: source.name,
              subtitle: source.publisher ?? source.type ?? 'Nguồn xuất bản',
              trailing: '${source.worksCount} bài báo',
              icon: Icons.book_outlined,
              meta: '${source.citedByCount} trích dẫn',
            );
          },
        );

      case 'Institutions':
        if (controller.institutions.isEmpty && !controller.isLoading) {
          return const EmptyStateWidget(message: 'Không tìm thấy tổ chức nào.');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.institutions.length,
          itemBuilder: (context, index) {
            final inst = controller.institutions[index];
            return _buildEntityCard(
              title: inst.name,
              subtitle: '${inst.type ?? 'Tổ chức'} • ${inst.countryCode ?? ''}',
              trailing: '${inst.worksCount} bài báo',
              icon: Icons.account_balance_outlined,
              meta: '${inst.citedByCount} trích dẫn',
            );
          },
        );

      default:
        return const EmptyStateWidget(message: 'Danh mục không xác định');
    }
  }

  Widget _buildEntityCard({
    required String title,
    required String subtitle,
    required String trailing,
    required IconData icon,
    required String meta,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
<<<<<<< Updated upstream
          border: Border.all(color: AppColors.secondary, width: 1.0),
=======
          border: Border.all(color: AppColors.outline, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
>>>>>>> Stashed changes
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              child: Icon(icon, color: AppColors.accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(meta, style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
<<<<<<< Updated upstream
            Text(trailing, style: AppTextStyles.labelCaps),
=======
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(trailing, style: AppTextStyles.labelCaps.copyWith(fontSize: 10)),
            ),
>>>>>>> Stashed changes
          ],
        ),
      ),
    );
  }
}
