import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';
import 'messaging_view_model.dart';

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  late final MessagingViewModel _viewModel;
  final _topicController = TextEditingController(text: 'announcements');
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = MessagingViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _topicController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Messaging',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bodyController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Body',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_viewModel.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _viewModel.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_viewModel.lastMessageId != null) ...[
                      const SizedBox(height: 12),
                      Text('Sent: ${_viewModel.lastMessageId}'),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _viewModel.isLoading ? null : _send,
                        icon: _viewModel.isLoading
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: const Text('Send to topic'),
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

  Future<void> _send() async {
    await _viewModel.sendTopicMessage(
      topic: _topicController.text.trim(),
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
    );
  }
}
