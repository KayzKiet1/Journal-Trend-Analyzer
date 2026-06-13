import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/analysis_helper.dart';
import '../widgets/stat_card.dart'; // 1. Import StatCard mới vào hệ thống

/// Màn hình Dashboard tổng quan hiển thị các số liệu thống kê phân tích
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

          // Tính toán các chỉ số
          final avgCitations = AnalysisHelper.getAverageCitations(publications);
          final topJournals = AnalysisHelper.getTopJournals(publications);
          final topAuthors = AnalysisHelper.getTopAuthors(publications);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số liệu tổng quan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Lưới hiển thị các thẻ thông số thống kê chính
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // 2. Sử dụng class StatCard thay cho hàm build cũ
                    StatCard(
                      title: 'Tổng số bài báo', 
                      value: '${publications.length}',
                    ),
                    StatCard(
                      title: 'Trích dẫn trung bình', 
                      value: avgCitations.toStringAsFixed(1),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Top 5 Tạp chí phổ biến',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  color: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: topJournals.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = topJournals.entries.elementAt(index);
                        return _buildListItem(entry.key, '${entry.value} bài báo');
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Top 5 Tác giả nổi bật',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  color: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: topAuthors.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = topAuthors.entries.elementAt(index);
                        return _buildListItem(entry.key, 'Đóng góp ${entry.value} lượt');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  // 3. Hàm _buildStatCard cũ đã được loại bỏ hoàn toàn tại đây để tránh code rác

  /// Widget hiển thị mục trong danh sách (Tác giả/Tạp chí)
  Widget _buildListItem(String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Icon(Icons.star, color: Colors.white, size: 16),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    );
  }
}