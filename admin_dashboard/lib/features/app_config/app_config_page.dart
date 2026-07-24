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
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Firestore document: app_config/main',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _jsonController,
                minLines: 16,
                maxLines: 28,
                decoration: const InputDecoration(
                  labelText: 'Config JSON',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              if (_viewModel.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _viewModel.isLoading ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save config'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    await _viewModel.saveConfig(_jsonController.text);
    if (mounted && _viewModel.errorMessage == null) {
      _jsonController.text = _viewModel.jsonText;
    }
  }
}
