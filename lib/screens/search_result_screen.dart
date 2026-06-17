import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/app_drawer.dart';
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';
import 'home_screen.dart';

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
    bool isSubPage = widget.category == 'AuthorWorks';

    if (widget.category == 'AuthorWorks') {
      displayTitle = 'Bài báo của ${widget.topic}';
    } else {
      displayTitle = '${widget.category}: ${widget.topic}';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isSubPage ? null : AppDrawer(
        currentRoute: widget.category == 'Sources' ? 'journal' : '',
      ),
      appBar: AppBar(
        title: Text(displayTitle),
        leading: isSubPage 
          ? null 
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              );
            },
            tooltip: 'Tìm kiếm mới',
          ),
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
        builder: (context, controller, child) {
          if (controller.isLoading && controller.publications.isEmpty && controller.authors.isEmpty && controller.sources.isEmpty && controller.institutions.isEmpty) {
            return const LoadingWidget();
          }

          if (controller.errorMessage.isNotEmpty && controller.publications.isEmpty) {
            return Center(child: Text(controller.errorMessage));
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
                child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
              );
            }

            final pub = controller.publications[index];
            return PublicationCard(
              title: pub.title,
              authors: pub.authorsString,
              journal: pub.journalName,
              year: pub.publicationYear.toString(),
              citations: pub.citedByCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublicationDetailScreen(publication: pub),
                  ),
                );
              },
            );
          },
        );
      case 'Authors':
        if (controller.authors.isEmpty && !controller.isLoading) return const EmptyStateWidget(message: 'Không tìm thấy tác giả nào.');
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.authors.length + (controller.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.authors.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
              );
            }

            final author = controller.authors[index];
            return _buildEntityCard(
              title: author.name,
              subtitle: author.lastKnownInstitution ?? 'No institution info',
              trailing: '${author.worksCount} works',
              icon: Icons.person_outline,
              meta: '${author.citedByCount} citations',
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
        if (controller.sources.isEmpty) return const EmptyStateWidget(message: 'Không tìm thấy nguồn nào.');
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.sources.length,
          itemBuilder: (context, index) {
            final source = controller.sources[index];
            return _buildEntityCard(
              title: source.name,
              subtitle: source.publisher ?? source.type ?? 'Source',
              trailing: '${source.worksCount} works',
              icon: Icons.book_outlined,
              meta: '${source.citedByCount} citations',
            );
          },
        );
      case 'Institutions':
        if (controller.institutions.isEmpty) return const EmptyStateWidget(message: 'Không tìm thấy tổ chức nào.');
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.institutions.length,
          itemBuilder: (context, index) {
            final inst = controller.institutions[index];
            return _buildEntityCard(
              title: inst.name,
              subtitle: '${inst.type ?? 'Institution'} • ${inst.countryCode ?? ''}',
              trailing: '${inst.worksCount} works',
              icon: Icons.account_balance_outlined,
              meta: '${inst.citedByCount} citations',
            );
          },
        );
      default:
        return const EmptyStateWidget(message: 'Category unknown');
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
          border: Border.all(color: AppColors.secondary, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.format_quote, size: 12, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(meta, style: AppTextStyles.labelCaps.copyWith(color: AppColors.accent, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Text(trailing, style: AppTextStyles.labelCaps.copyWith(fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}
