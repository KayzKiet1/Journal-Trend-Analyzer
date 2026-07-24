import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'app_config_view_model.dart';

/// Trang quản lý cấu hình hệ thống (App Config).
/// Cho phép Admin chỉnh sửa dữ liệu cấu hình dưới dạng JSON và lưu trực tiếp vào Firestore.
class AppConfigPage extends StatefulWidget {
  const AppConfigPage({super.key});

  @override
  State<AppConfigPage> createState() => _AppConfigPageState();
}

class _AppConfigPageState extends State<AppConfigPage> {
  late final AppConfigViewModel _viewModel;
  final _jsonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = AppConfigViewModel()
      ..loadConfig().then((_) {
        if (mounted) {
          _jsonController.text = _viewModel.jsonText;
        }
      });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Cấu hình Hệ thống',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          // Trạng thái đang tải cấu hình.
          if (_viewModel.isLoading && _viewModel.config.isEmpty) {
            return const LoadingView();
          }

          // Trạng thái gặp lỗi khi tải cấu hình.
          if (_viewModel.errorMessage != null && _viewModel.config.isEmpty) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          return ListView(
            padding: const EdgeInsets.all(32),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tài liệu Firestore: app_config/main',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chỉnh sửa các tham số ứng dụng bằng định dạng JSON bên dưới. Cẩn thận khi thay đổi các khóa dữ liệu.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    
                    // Ô nhập liệu JSON với Font chữ Monospace chuyên nghiệp.
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _jsonController,
                        minLines: 16,
                        maxLines: 32,
                        style: const TextStyle(
                          fontFamily: 'monospace', // Font chữ lập trình
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nội dung cấu hình JSON',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          alignLabelWithHint: true,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                    
                    // Thông báo lỗi nếu lưu thất bại.
                    if (_viewModel.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _viewModel.errorMessage!,
                                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Nút lưu cấu hình.
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _viewModel.isLoading ? null : _save,
                        icon: _viewModel.isLoading 
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                        label: const Text('Lưu cấu hình'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Thực hiện lưu cấu hình thông qua ViewModel.
  Future<void> _save() async {
    await _viewModel.saveConfig(_jsonController.text);
    if (mounted && _viewModel.errorMessage == null) {
      _jsonController.text = _viewModel.jsonText;
      // Hiển thị thông báo thành công.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cấu hình thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
