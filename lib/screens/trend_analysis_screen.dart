import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/analysis_controller.dart';
import '../models/trend_data_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/year_trend_chart.dart';
import '../widgets/loading_widget.dart';
import 'dashboard_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisController>().fetchTrendAnalysis(widget.topic);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Xu hướng: ${widget.topic}'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            },
            icon: const Icon(Icons.dashboard_customize),
            label: Text('DASHBOARD', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary)),
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

          // Logic tìm năm tích cực nhất dựa trên dữ liệu thật
          TrendData? mostActiveTrend;
          if (controller.trends.isNotEmpty) {
            mostActiveTrend = controller.trends.reduce((curr, next) => curr.count > next.count ? curr : next);
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    YearTrendChart(trends: controller.trends),
                    
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'PHÂN TÍCH CHI TIẾT',
                      style: AppTextStyles.labelCaps,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    if (controller.trends.isNotEmpty && mostActiveTrend != null) ...[
                      _buildInsightCard(
                        Icons.trending_up, 
                        'Năm hoạt động mạnh nhất', 
                        'Năm ${mostActiveTrend.year} có số lượng bài báo cao nhất với ${mostActiveTrend.count} công trình.'
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
