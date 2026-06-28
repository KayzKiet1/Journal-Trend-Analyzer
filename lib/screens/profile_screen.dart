import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/publication_controller.dart';
import '../controllers/analysis_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final userController = context.read<UserController>();
    _emailController.text = userController.email;
    _apiKeyController.text = userController.apiKey;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final email = _emailController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    
    if (email.isNotEmpty && email.contains('@')) {
      final userController = context.read<UserController>();
      userController.updateEmail(email);
      userController.updateApiKey(apiKey);
      
      // Cập nhật email và API Key cho các API Service trong controllers
      context.read<PublicationController>().updateApiService(email, apiKey: apiKey);
      context.read<AnalysisController>().updateApiService(email, apiKey: apiKey);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thiết lập OpenAlex thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email hợp lệ.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hồ sơ người dùng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THIẾT LẬP OPENALEX', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.secondary, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email giúp nhận diện "Polite Pool", API Key giúp tăng giới hạn truy vấn.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email liên hệ',
                      hintText: 'example@domain.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'OpenAlex API Key (Tùy chọn)',
                      hintText: 'Nhập API Key của bạn',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('LƯU THÔNG TIN'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('VỀ ỨNG DỤNG', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.md),
            _buildInfoCard(
              'Phiên bản',
              '1.0.0 (PRM393 Lab2)',
              Icons.info_outline,
            ),
            _buildInfoCard(
              'Nguồn dữ liệu',
              'OpenAlex API (Hệ thống dữ liệu học thuật mở)',
              Icons.cloud_outlined,
            ),
            _buildInfoCard(
              'Thiết kế',
              'Heritage Design System (Minimalism)',
              Icons.palette_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded( // Thêm Expanded để tránh lỗi overflow khi text quá dài
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelCaps.copyWith(fontSize: 10)),
                Text(
                  value, 
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                  maxLines: 2, // Cho phép hiển thị tối đa 2 dòng
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
