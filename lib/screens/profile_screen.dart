import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/publication_controller.dart';
import '../controllers/analysis_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = context.read<UserController>().email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _saveEmail() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && email.contains('@')) {
      context.read<UserController>().updateEmail(email);
      
      // Cập nhật email cho các API Service trong controllers
      context.read<PublicationController>().updateApiService(email);
      context.read<AnalysisController>().updateApiService(email);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật email. Bạn đã tham gia Polite Pool của OpenAlex!'),
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
      drawer: const AppDrawer(currentRoute: 'profile'),
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
                    'Email của bạn giúp OpenAlex nhận diện người dùng và đưa bạn vào "Polite Pool", giúp truy vấn nhanh và ổn định hơn.',
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
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveEmail,
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
