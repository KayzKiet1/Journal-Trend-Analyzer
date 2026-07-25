import 'package:flutter/material.dart';

import '../../data/models/app_config.dart';
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
  final _maxJournalsController = TextEditingController();
  final _maxKeywordsController = TextEditingController();
  final _firestoreJsonController = TextEditingController(text: '{}');
  bool _enableReportExport = true;

  @override
  void initState() {
    super.initState();
    _viewModel = AppConfigViewModel()..load().then((_) => _syncControllers());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _maxJournalsController.dispose();
    _maxKeywordsController.dispose();
    _firestoreJsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'App Config',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.firestoreConfig.isEmpty) {
            return const LoadingView();
          }

          if (_viewModel.errorMessage != null &&
              _viewModel.firestoreConfig.isEmpty) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ConfigIntro(),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 920;
                        final remoteCard = _RemoteConfigCard(
                          maxJournalsController: _maxJournalsController,
                          maxKeywordsController: _maxKeywordsController,
                          enableReportExport: _enableReportExport,
                          version: _viewModel.remoteVersion,
                          isSaving: _viewModel.isSavingRemote,
                          onExportChanged: (value) {
                            setState(() => _enableReportExport = value);
                          },
                          onSave: _saveRemoteConfig,
                        );
                        final firestoreCard = _FirestoreConfigCard(
                          controller: _firestoreJsonController,
                          isSaving: _viewModel.isSavingFirestore,
                          onReload: _viewModel.isBusy ? null : _reload,
                          onSave: _viewModel.isBusy
                              ? null
                              : _saveFirestoreConfig,
                        );

                        if (!twoColumns) {
                          return Column(
                            children: [
                              remoteCard,
                              const SizedBox(height: 16),
                              firestoreCard,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: remoteCard),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: firestoreCard),
                          ],
                        );
                      },
                    ),
                    if (_viewModel.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _StatusBanner(message: _viewModel.errorMessage!),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _reload() async {
    await _viewModel.load();
    if (mounted && _viewModel.errorMessage == null) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    if (!mounted) return;
    final remoteConfig = _viewModel.remoteConfig;
    setState(() {
      _maxJournalsController.text = remoteConfig.maxJournalsDisplay.toString();
      _maxKeywordsController.text = remoteConfig.maxKeywordsDisplay.toString();
      _enableReportExport = remoteConfig.enableReportExport;
      _firestoreJsonController.text = _viewModel.firestoreJsonText;
    });
  }

  Future<void> _saveRemoteConfig() async {
    await _viewModel.saveRemoteConfig(
      RemoteAppConfig(
        maxJournalsDisplay: int.tryParse(_maxJournalsController.text) ?? 0,
        maxKeywordsDisplay: int.tryParse(_maxKeywordsController.text) ?? 0,
        enableReportExport: _enableReportExport,
      ),
    );

    if (!mounted || _viewModel.errorMessage != null) return;
    _syncControllers();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã publish Remote Config cho mobile app.')),
    );
  }

  Future<void> _saveFirestoreConfig() async {
    await _viewModel.saveFirestoreConfig(_firestoreJsonController.text);
    if (!mounted || _viewModel.errorMessage != null) return;
    _syncControllers();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu Firestore app_config/main.')),
    );
  }
}

class _ConfigIntro extends StatelessWidget {
  const _ConfigIntro();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
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
                    'Configuration center',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Runtime settings for mobile use Firebase Remote Config. Internal admin settings stay in Firestore app_config/main.',
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

class _RemoteConfigCard extends StatelessWidget {
  const _RemoteConfigCard({
    required this.maxJournalsController,
    required this.maxKeywordsController,
    required this.enableReportExport,
    required this.version,
    required this.isSaving,
    required this.onExportChanged,
    required this.onSave,
  });

  final TextEditingController maxJournalsController;
  final TextEditingController maxKeywordsController;
  final bool enableReportExport;
  final RemoteConfigVersion? version;
  final bool isSaving;
  final ValueChanged<bool> onExportChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.mobile_friendly_outlined,
              title: 'Mobile Runtime Config',
              subtitle:
                  'Publish trực tiếp lên Firebase Remote Config cho mobile app.',
            ),
            const SizedBox(height: 16),
            _NumberField(
              controller: maxJournalsController,
              label: 'Max journals display',
              helperText: 'Remote key: max_journals_display',
            ),
            const SizedBox(height: 14),
            _NumberField(
              controller: maxKeywordsController,
              label: 'Max keywords display',
              helperText: 'Remote key: max_keywords_display',
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: enableReportExport,
              onChanged: onExportChanged,
              secondary: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text(
                'Enable report export',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Remote key: enable_report_export'),
            ),
            const Divider(),
            _RemoteVersionInfo(version: version),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Publish Remote Config'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirestoreConfigCard extends StatelessWidget {
  const _FirestoreConfigCard({
    required this.controller,
    required this.isSaving,
    required this.onReload,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback? onReload;
  final VoidCallback? onSave;

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
              title: 'Internal Firestore Config',
              subtitle:
                  'Dành cho cấu hình nội bộ admin/backend: app_config/main.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              minLines: 18,
              maxLines: 26,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.35,
              ),
              decoration: const InputDecoration(
                labelText: 'Firestore JSON',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onSave,
                  icon: isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Firestore Config'),
                ),
                OutlinedButton.icon(
                  onPressed: onReload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        helperText: '$helperText • allowed: 1-100',
        prefixIcon: const Icon(Icons.format_list_numbered_outlined),
      ),
    );
  }
}

class _RemoteVersionInfo extends StatelessWidget {
  const _RemoteVersionInfo({required this.version});

  final RemoteConfigVersion? version;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentVersion = version;

    if (currentVersion == null) {
      return Text(
        'Remote Config version chưa có trong response.',
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoLine(label: 'Version', value: currentVersion.versionNumber),
        _InfoLine(label: 'Updated', value: currentVersion.updateTime),
        _InfoLine(label: 'By', value: currentVersion.updateUserEmail),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '-' : value)),
        ],
      ),
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
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
