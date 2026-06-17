import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../utils/analysis_helper.dart';
import '../widgets/stat_card.dart';
import '../widgets/horizontal_bar_chart.dart';
import '../widgets/publication_card.dart';
import '../widgets/app_drawer.dart';
import 'publication_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bảng điều khiển nghiên cứu'),
      ),
      drawer: const AppDrawer(currentRoute: 'keywords'),
      body: Consumer<PublicationController>(
        builder: (context, controller, child) {
          final publications = controller.publications;

          if (publications.isEmpty) {
            return const Center(
              child: Text('Không có dữ liệu để phân tích.'),
            );
          }

          final totalPublications = controller.totalResults > 0 
              ? controller.totalResults.toString() 
              : publications.length.toString();
          
          final totalCitations = controller.totalCitationsGlobal > 0
              ? controller.totalCitationsGlobal.toString()
              : AnalysisHelper.getTotalCitations(publications).toString();
              
          final avgCitations = (int.parse(totalCitations) / int.parse(totalPublications)).toStringAsFixed(1);

          final mostActiveYear = 
              AnalysisHelper.getMostActivePublicationYear(publications)?.toString() ?? 'N/A';

          final topJournals = AnalysisHelper.getTopJournals(publications);
          final topAuthors = AnalysisHelper.getTopAuthors(publications);
          
          // Chuyển đổi Map sang List<Map<String, dynamic>> cho HorizontalBarChart
          final journalData = topJournals.entries.map((e) => {'name': e.key, 'count': e.value}).toList();
          final authorData = topAuthors.entries.map((e) => {'name': e.key, 'count': e.value}).toList();

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
                        final crossAxisCount =
                            constraints.maxWidth >= 600 ? 4 : 2;

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: constraints.maxWidth >= 600 ? 1.5 : 1.2,
                          children: [
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
                          ],
                        );
                      },
                    ),

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

                    // Sử dụng LayoutBuilder để tự động chuyển sang Column trên màn hình hẹp
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HorizontalBarChart(
                                data: journalData, 
                                title: 'TOP 5 TẠP CHÍ PHỔ BIẾN',
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              HorizontalBarChart(
                                data: authorData, 
                                title: 'TOP 5 TÁC GIẢ ĐÓNG GÓP',
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: HorizontalBarChart(
                                  data: journalData, 
                                  title: 'TOP 5 TẠP CHÍ PHỔ BIẾN',
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xl),
                              Expanded(
                                child: HorizontalBarChart(
                                  data: authorData, 
                                  title: 'TOP 5 TÁC GIẢ ĐÓNG GÓP',
                                ),
                              ),
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
