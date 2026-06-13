import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../widgets/publication_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/app_button.dart'; // 1. Thêm import AppButton
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';

/// Màn hình hiển thị kết quả tìm kiếm các bài báo theo chủ đề
class SearchResultScreen extends StatefulWidget {
  final String topic;

  const SearchResultScreen({super.key, required this.topic});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi API tìm kiếm sau khi màn hình được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicationController>().searchByTopic(widget.topic);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kết quả: ${widget.topic}',
          style: const TextStyle(color: AppColors.textInverted),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textInverted),
        // 2. Giữ lại nút trên AppBar hoặc xóa bỏ tùy nhu cầu. 
        // Để UI tập trung vào AppButton bên dưới, ta giữ nguyên hoặc có thể lược bỏ.
        actions: [
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
          ),
        ],
      ),
      body: Consumer<PublicationController>(
        builder: (context, controller, child) {
          // Hiển thị vòng xoay loading khi đang tải dữ liệu
          if (controller.isLoading) {
            return const LoadingWidget();
          }

          // Hiển thị thông báo lỗi nếu có
          if (controller.errorMessage.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  controller.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          // Hiển thị danh sách các bài báo
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: controller.publications.length,
            itemBuilder: (context, index) {
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
        },
      ),
      // 3. Loại bỏ hoàn toàn `floatingActionButton` cũ rườm rà.
      // 4. Thay thế bằng `bottomNavigationBar` cố định phía dưới màn hình để mang lại cảm giác cao cấp, vững chãi.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md), // Khoảng đệm 16px chuẩn hệ thống
          child: AppButton(
            text: 'Phân tích xu hướng',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrendAnalysisScreen(topic: widget.topic),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}