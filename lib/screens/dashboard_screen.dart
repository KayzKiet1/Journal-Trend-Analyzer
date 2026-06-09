import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/analysis_helper.dart';

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
                  'Số liệu thống kê nhanh',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Hiển thị các thẻ thông số
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Tổng bài báo', publications.length.toString()),
                    _buildStatCard('Trích dẫn TB', avgCitations.toStringAsFixed(1)),
                    _buildStatCard('Chủ đề', controller.currentTopic),
                    _buildStatCard('Nguồn tin', topJournals.length.toString()),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Danh sách các tạp chí hàng đầu
                const Text(
                  'Tạp chí xuất bản nhiều nhất',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...topJournals.entries.map((e) => _buildListItem(e.key, '${e.value} bài báo')),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Danh sách các tác giả hàng đầu
                const Text(
                  'Tác giả đóng góp nhiều nhất',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...topAuthors.entries.map((e) => _buildListItem(e.key, '${e.value} bài báo')),
                
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Widget hiển thị thẻ thông số
  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Widget hiển thị mục trong danh sách (Tác giả/Tạp chí)
  Widget _buildListItem(String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Icon(Icons.star, color: Colors.white, size: 16),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
