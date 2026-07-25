import 'dart:convert';

import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'app_config_view_model.dart';

class AppConfigPage extends StatefulWidget {
  const AppConfigPage({super.key});

  @override
  State<AppConfigPage> createState() => _AppConfigPageState();
}

class _AppConfigPageState extends State<AppConfigPage> {
  late final AppConfigViewModel _viewModel;
  final _maxJournalsController = TextEditingController(text: '10');
  final _announcementController = TextEditingController();
  final _advancedJsonController = TextEditingController(text: '{}');
  bool _maintenanceMode = false;
  bool _enableReportExport = true;

  @override
  void initState() {
    super.initState();
    _viewModel = AppConfigViewModel();
    _loadConfig();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _maxJournalsController.dispose();
    _announcementController.dispose();
    _advancedJsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdminShell(
      title: 'App Config',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.config.isEmpty) {
            return const LoadingView();
          }

          if (_viewModel.errorMessage != null && _viewModel.config.isEmpty) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PageIntro(colorScheme: colorScheme),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useTwoColumns = constraints.maxWidth >= 900;
                        final form = _ConfigForm(
                          maintenanceMode: _maintenanceMode,
                          enableReportExport: _enableReportExport,
                          maxJournalsController: _maxJournalsController,
                          announcementController: _announcementController,
                          onMaintenanceChanged: (value) =>
                              setState(() => _maintenanceMode = value),
                          onReportExportChanged: (value) =>
                              setState(() => _enableReportExport = value),
                        );
                        final advanced = _AdvancedConfigEditor(
                          controller: _advancedJsonController,
                        );

                        if (!useTwoColumns) {
                          return Column(
                            children: [
                              form,
                              const SizedBox(height: 16),
                              advanced,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: form),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: advanced),
                          ],
                        );
                      },
                    ),
                    if (_viewModel.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _StatusBanner(
                        icon: Icons.error_outline,
                        message: _viewModel.errorMessage!,
                        color: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _SaveBar(
                      isLoading: _viewModel.isLoading,
                      onReload: _viewModel.isLoading ? null : _loadConfig,
                      onSave: _viewModel.isLoading ? null : _save,
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

  Future<void> _loadConfig() async {
    await _viewModel.loadConfig();
    if (mounted && _viewModel.errorMessage == null) {
      setState(_syncControllers);
    }
  }

  void _syncControllers() {
    final config = _viewModel.config;
    _maintenanceMode = config['maintenanceMode'] == true;
    _enableReportExport = config['enableReportExport'] != false;
    _maxJournalsController.text =
        config['maxJournalsDisplay']?.toString() ?? '10';
    _announcementController.text = config['announcementText']?.toString() ?? '';

    final advanced = Map<String, dynamic>.from(config)
      ..remove('maintenanceMode')
      ..remove('enableReportExport')
      ..remove('maxJournalsDisplay')
      ..remove('announcementText')
      ..remove('updatedAt');

    _advancedJsonController.text = const JsonEncoder.withIndent(
      '  ',
    ).convert(advanced);
  }

  Future<void> _save() async {
    await _viewModel.saveTypedConfig(
      maintenanceMode: _maintenanceMode,
      enableReportExport: _enableReportExport,
      maxJournalsDisplay: int.tryParse(_maxJournalsController.text) ?? 10,
      announcementText: _announcementController.text.trim(),
      advancedJson: _advancedJsonController.text.trim().isEmpty
          ? '{}'
          : _advancedJsonController.text,
    );

    if (!mounted || _viewModel.errorMessage != null) {
      return;
    }

    setState(_syncControllers);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu cấu hình app.')));
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.tune, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firestore document: app_config/main',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Các thay đổi tại đây được lưu qua Cloud Functions, có kiểm tra admin claim và ghi audit log.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigForm extends StatelessWidget {
  const _ConfigForm({
    required this.maintenanceMode,
    required this.enableReportExport,
    required this.maxJournalsController,
    required this.announcementController,
    required this.onMaintenanceChanged,
    required this.onReportExportChanged,
  });

  final bool maintenanceMode;
  final bool enableReportExport;
  final TextEditingController maxJournalsController;
  final TextEditingController announcementController;
  final ValueChanged<bool> onMaintenanceChanged;
  final ValueChanged<bool> onReportExportChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.settings_applications_outlined,
              title: 'General controls',
              subtitle: 'Các cấu hình nên chỉnh bằng form để giảm lỗi dữ liệu.',
            ),
            const SizedBox(height: 12),
            _ConfigSwitchTile(
              title: 'Maintenance mode',
              subtitle: 'Bật khi cần tạm ngưng app cho người dùng.',
              icon: Icons.construction_outlined,
              value: maintenanceMode,
              onChanged: onMaintenanceChanged,
            ),
            const Divider(),
            _ConfigSwitchTile(
              title: 'Report export',
              subtitle: 'Cho phép người dùng export report từ app.',
              icon: Icons.picture_as_pdf_outlined,
              value: enableReportExport,
              onChanged: onReportExportChanged,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: maxJournalsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max journals display',
                prefixIcon: Icon(Icons.format_list_numbered_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: announcementController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Announcement text',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.campaign_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedConfigEditor extends StatelessWidget {
  const _AdvancedConfigEditor({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.data_object,
              title: 'Advanced JSON',
              subtitle: 'Chỉ thêm các key nâng cao chưa có form riêng.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              minLines: 15,
              maxLines: 24,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.35,
              ),
              decoration: const InputDecoration(
                labelText: 'Additional config',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigSwitchTile extends StatelessWidget {
  const _ConfigSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.foregroundColor,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: foregroundColor)),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isLoading,
    required this.onReload,
    required this.onSave,
  });

  final bool isLoading;
  final VoidCallback? onReload;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: onSave,
          icon: isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save config'),
        ),
        OutlinedButton.icon(
          onPressed: onReload,
          icon: const Icon(Icons.refresh),
          label: const Text('Reload'),
        ),
      ],
    );
  }
}
