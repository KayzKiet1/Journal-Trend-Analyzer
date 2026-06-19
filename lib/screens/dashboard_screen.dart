import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/publication_controller.dart';
import '../controllers/analysis_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../utils/analysis_helper.dart';
import '../widgets/stat_card.dart';
import '../widgets/horizontal_bar_chart.dart';
import '../widgets/publication_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/loading_widget.dart';
import '../widgets/year_trend_chart.dart';
import 'publication_detail_screen.dart';

<<<<<<< Updated upstream
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
=======
class DashboardScreen extends StatefulWidget {
  final String route;
  const DashboardScreen({super.key, this.route = 'journal'});
>>>>>>> Stashed changes

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pubController = context.read<PublicationController>();
      // Nếu có từ khóa tìm kiếm, hãy chạy phân tích chuyên sâu ngay
      if (pubController.currentTopic.isNotEmpty) {
        context.read<AnalysisController>().fetchTrendAnalysis(pubController.currentTopic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bảng điều khiển nghiên cứu'),
      ),
<<<<<<< Updated upstream
      drawer: const AppDrawer(currentRoute: 'keywords'),
      body: Consumer<PublicationController>(
        builder: (context, controller, child) {
          final publications = controller.publications;
=======
      body: Consumer2<PublicationController, AnalysisController>(
        builder: (context, pubController, analysisController, child) {
          final publications = pubController.publications;
>>>>>>> Stashed changes

          if (publications.isEmpty && !analysisController.isLoading) {
            return const Center(
              child: Text('Không có dữ liệu để phân tích. Hãy thực hiện tìm kiếm trước.'),
            );
          }

          // Lấy dữ liệu thống kê tổng quát
          final totalPublications = pubController.totalResults > 0 
              ? pubController.totalResults.toString() 
              : publications.length.toString();
          
          final totalCitations = pubController.totalCitationsGlobal > 0
              ? pubController.totalCitationsGlobal.toString()
              : AnalysisHelper.getTotalCitations(publications).toString();
              
          final avgCitations = (int.parse(totalCitations) / int.parse(totalPublications)).toStringAsFixed(1);

          final mostActiveYear = 
              AnalysisHelper.getMostActivePublicationYear(publications)?.toString() ?? 'N/A';

          // Dữ liệu biểu đồ: Ưu tiên dữ liệu Global từ AnalysisController
          List<Map<String, dynamic>> journalData = analysisController.topJournals.take(5).toList();
          List<Map<String, dynamic>> authorData = analysisController.topAuthors.take(5).toList();

          // Fallback nếu dữ liệu Global chưa có hoặc đang tải
          if (authorData.isEmpty) {
            final topAuthors = AnalysisHelper.getTopAuthors(publications);
            authorData = topAuthors.entries.map((e) => {'name': e.key, 'count': e.value}).toList();
          }
          if (journalData.isEmpty) {
            final topJournals = AnalysisHelper.getTopJournals(publications);
            journalData = topJournals.entries.map((e) => {'name': e.key, 'count': e.value}).toList();
          }

          final topPapers = AnalysisHelper.getTopCitedPapers(publications, limit: 5);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THỐNG KÊ TỔNG QUAN',
                      style: AppTextStyles.labelCaps,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth >= 600 ? 4 : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: constraints.maxWidth >= 600 ? 1.5 : 1.2,
                          children: [
<<<<<<< Updated upstream
                            StatCard(
                              title: 'Tổng bài báo',
                              value: totalPublications,
                            ),
                            StatCard(
                              title: 'Tổng trích dẫn',
                              value: totalCitations,
                            ),
                            StatCard(
                              title: 'Trích dẫn TB',
                              value: avgCitations,
                            ),
                            StatCard(
                              title: 'Năm tích cực nhất',
                              value: mostActiveYear,
                            ),
=======
                            StatCard(title: 'Tổng bài báo', value: totalPublications, icon: Icons.article_outlined),
                            StatCard(title: 'Tổng trích dẫn', value: totalCitations, icon: Icons.format_quote),
                            StatCard(title: 'Trích dẫn TB', value: avgCitations, icon: Icons.analytics_outlined),
                            StatCard(title: 'Năm tích cực', value: mostActiveYear, icon: Icons.calendar_today_outlined),
>>>>>>> Stashed changes
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl * 1.5),

                    Text(
                      'XU HƯỚNG CÔNG BỐ (TRENDS)',
                      style: AppTextStyles.labelCaps,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    YearTrendChart(trends: analysisController.trends),

                    const SizedBox(height: AppSpacing.xl * 1.5),
                    
                    Text(
                      'TOP 5 BÀI BÁO CÓ ẢNH HƯỞNG NHẤT',
                      style: AppTextStyles.labelCaps,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...topPapers.map((pub) => PublicationCard(
                      title: pub.title,
                      year: pub.publicationYear.toString(),
                      journal: pub.journalName,
                      authors: pub.authorsString,
                      citations: pub.citedByCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PublicationDetailScreen(publication: pub),
                          ),
                        );
                      },
                    )),

                    const SizedBox(height: AppSpacing.xl * 1.5),

                    // Phần biểu đồ
                    if (analysisController.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 600) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HorizontalBarChart(data: journalData, title: 'TOP 5 TẠP CHÍ PHỔ BIẾN'),
                                const SizedBox(height: AppSpacing.xl),
                                HorizontalBarChart(data: authorData, title: 'TOP 5 TÁC GIẢ ĐÓNG GÓP'),
                              ],
                            );
                          } else {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: HorizontalBarChart(data: journalData, title: 'TOP 5 TẠP CHÍ PHỔ BIẾN')),
                                const SizedBox(width: AppSpacing.xl),
                                Expanded(child: HorizontalBarChart(data: authorData, title: 'TOP 5 TÁC GIẢ ĐÓNG GÓP')),
                              ],
                            );
                          }
                        },
                      ),
                    const SizedBox(height: AppSpacing.xl * 2),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
