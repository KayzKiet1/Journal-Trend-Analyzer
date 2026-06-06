import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/analysis_controller.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../widgets/year_trend_chart.dart';
import '../widgets/loading_widget.dart';
import 'dashboard_screen.dart';

/// Màn hình phân tích xu hướng và hiển thị biểu đồ theo thời gian
class TrendAnalysisScreen extends StatefulWidget {
  final String topic;

  const TrendAnalysisScreen({super.key, required this.topic});

  @override
  State<TrendAnalysisScreen> createState() => _TrendAnalysisScreenState();
}

class _TrendAnalysisScreenState extends State<TrendAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi API lấy dữ liệu xu hướng sau khi màn hình được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisController>().fetchTrendAnalysis(widget.topic);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Xu hướng: ${widget.topic}', style: const TextStyle(color: AppColors.textInverted)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textInverted),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            },
            icon: const Icon(Icons.dashboard_customize, color: AppColors.textInverted),
            label: const Text('Tổng quan', style: TextStyle(color: AppColors.textInverted)),
          ),
        ],
      ),
      body: Consumer<AnalysisController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const LoadingWidget();
          }

          if (controller.errorMessage.isNotEmpty) {
            return Center(child: Text(controller.errorMessage));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Biểu đồ xu hướng theo năm
                YearTrendChart(trends: controller.trends),
                
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Phân tích chi tiết',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Hiển thị các nhận định dựa trên dữ liệu thật
                if (controller.trends.isNotEmpty) ...[
                  _buildInsightCard(
                    Icons.trending_up, 
                    'Năm hoạt động mạnh nhất', 
                    'Năm ${controller.trends.last.year} có số lượng bài báo cao nhất với ${controller.trends.last.count} công trình.'
                  ),
                  _buildInsightCard(
                    Icons.history, 
                    'Giai đoạn nghiên cứu', 
                    'Dữ liệu bao gồm các nghiên cứu từ năm ${controller.trends.first.year} đến ${controller.trends.last.year}.'
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Widget hiển thị thẻ nhận định
  Widget _buildInsightCard(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
