import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/analysis_helper.dart';
import '../widgets/stat_card.dart';
import '../widgets/top_author_list.dart';
import '../widgets/top_journal_list.dart';

/// Màn hình Dashboard tổng quan hiển thị các số liệu thống kê phân tích
/// Đã được Thành viên 3 tích hợp đầy đủ cấu trúc Component chuẩn hóa
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bảng điều khiển nghiên cứu', style: TextStyle(color: AppColors.textInverted)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textInverted),
      ),
      body: Consumer<PublicationController>(
        builder: (context, controller, child) {
          final publications = controller.publications;
          
          if (publications.isEmpty) {
            return const Center(child: Text("Không có dữ liệu để phân tích."));
          }

          // Tính toán các chỉ số thông qua Helper của Thành viên 2
          final totalPublications = publications.length.toString();
          final totalCitations = AnalysisHelper.getTotalCitations(publications).toString();
          final avgCitations = AnalysisHelper.getAverageCitations(publications).toStringAsFixed(1);
          
          final topJournals = AnalysisHelper.getTopJournals(publications);
          final topAuthors = AnalysisHelper.getTopAuthors(publications);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê tổng quan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Sử dụng StatCard chuẩn thay vì build hàm cục bộ
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  children: [
                    StatCard(title: 'Tổng bài báo', value: totalPublications),
                    StatCard(title: 'Tổng trích dẫn', value: totalCitations),
                    StatCard(title: 'Trích dẫn TB', value: avgCitations),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Phân mục Top Tạp chí
                const Text(
                  'Top 5 Tạp chí phổ biến',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                TopJournalList(journals: topJournals), // Tích hợp Component chuẩn
                const SizedBox(height: AppSpacing.lg),

                // Phân mục Top Tác giả
                const Text(
                  'Top 5 Tác giả đóng góp',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                TopAuthorList(authors: topAuthors), // Tích hợp Component chuẩn
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}