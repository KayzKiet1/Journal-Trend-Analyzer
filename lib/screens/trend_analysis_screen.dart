import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/analysis_controller.dart';
import '../models/trend_data_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/year_trend_chart.dart';
import '../widgets/horizontal_bar_chart.dart';
import '../widgets/country_output_map.dart';
import '../widgets/donut_chart.dart';
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
        title: Text('Phân tích: ${widget.topic}'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(route: 'journal'),
                ),
              );
            },
            icon: const Icon(Icons.dashboard_customize),
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: Consumer<AnalysisController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const LoadingWidget();
          }

          if (controller.errorMessage.isNotEmpty && controller.trends.isEmpty) {
            return Center(child: Text(controller.errorMessage));
          }

          // Logic tìm năm tích cực nhất
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
                    // 1. Publication Trend (Line Chart)
                    Text('1. XU HƯỚNG CÔNG BỐ THEO NĂM', style: AppTextStyles.labelCaps),
                    const SizedBox(height: AppSpacing.md),
                    YearTrendChart(trends: controller.trends),
                    
                    const SizedBox(height: AppSpacing.xl),

                    // Top Influential Publications
                    HorizontalBarChart(
                      data: controller.topInfluentialWorks, 
                      title: 'ẤN PHẨM CÓ TẦM ẢNH HƯỞNG NHẤT',
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // 3. Top Keywords (Horizontal Bar)
                    HorizontalBarChart(
                      data: controller.topKeywords, 
                      title: '3. TOP TỪ KHÓA PHỔ BIẾN',
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),

                    // 7. Top Authors (Horizontal Bar)
                    HorizontalBarChart(
                      data: controller.topAuthors, 
                      title: '7. TOP TÁC GIẢ ĐÓNG GÓP',
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),

                    // 14. Journal Ranking (Horizontal Bar)
                    HorizontalBarChart(
                      data: controller.topJournals, 
                      title: '14. XẾP HẠNG TẠP CHÍ',
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),

                    // 12. Country Research Output (Map/List)
                    CountryOutputList(countries: controller.countryData),

                    const SizedBox(height: AppSpacing.xl),

                    // 10. Institution Ranking (Horizontal Bar)
                    HorizontalBarChart(
                      data: controller.institutions, 
                      title: '10. XẾP HẠNG TỔ CHỨC DẪN ĐẦU',
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // 16. Quartile Distribution (Donut Chart)
                    DonutChart(
                      data: controller.quartiles, 
                      title: '16. PHÂN BỐ CHẤT LƯỢNG (QUARTILE)',
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'INSIGHTS PHÂN TÍCH',
                      style: AppTextStyles.labelCaps,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    if (controller.trends.isNotEmpty && mostActiveTrend != null) ...[
                      _buildInsightCard(
                        Icons.trending_up, 
                        'Năm hoạt động mạnh nhất', 
                        'Năm ${mostActiveTrend.year} có số lượng ấn phẩm cao nhất với ${mostActiveTrend.count} nghiên cứu.'
                      ),
                      _buildInsightCard(
                        Icons.public, 
                        'Phạm vi quốc gia', 
                        'Các nghiên cứu về chủ đề này được thực hiện và công bố tại ${controller.countryData.length} quốc gia/vùng lãnh thổ.'
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
