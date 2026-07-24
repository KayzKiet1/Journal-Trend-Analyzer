import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';
import 'messaging_view_model.dart';

enum MessageTarget { allUsers, user, topic }

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  late final MessagingViewModel _viewModel;
  final _recipientController = TextEditingController();
  final _topicController = TextEditingController(text: 'announcements');
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  MessageTarget _target = MessageTarget.allUsers;

  @override
  void initState() {
    super.initState();
    _viewModel = MessagingViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _recipientController.dispose();
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
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<MessageTarget>(
                      segments: const [
                        ButtonSegment(
                          value: MessageTarget.allUsers,
                          icon: Icon(Icons.groups_outlined),
                          label: Text('All users'),
                        ),
                        ButtonSegment(
                          value: MessageTarget.user,
                          icon: Icon(Icons.person_outline),
                          label: Text('User'),
                        ),
                        ButtonSegment(
                          value: MessageTarget.topic,
                          icon: Icon(Icons.topic_outlined),
                          label: Text('Topic'),
                        ),
                      ],
                      selected: {_target},
                      onSelectionChanged: _viewModel.isLoading
                          ? null
                          : (value) => setState(() => _target = value.single),
                    ),
                    const SizedBox(height: 16),
                    if (_target == MessageTarget.user)
                      TextField(
                        controller: _recipientController,
                        decoration: const InputDecoration(
                          labelText: 'User email or uid',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (_target == MessageTarget.topic)
                      TextField(
                        controller: _topicController,
                        decoration: const InputDecoration(
                          labelText: 'Topic',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (_target != MessageTarget.allUsers)
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
                      Text('Sent message id: ${_viewModel.lastMessageId}'),
                    ],
                    if (_viewModel.lastDirectResult != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Sent: ${_viewModel.lastDirectResult!['successCount']} success, '
                        '${_viewModel.lastDirectResult!['failureCount']} failed',
                      ),
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
                        label: Text(_buttonLabel),
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

  String get _buttonLabel {
    switch (_target) {
      case MessageTarget.allUsers:
        return 'Send to all users';
      case MessageTarget.user:
        return 'Send to user';
      case MessageTarget.topic:
        return 'Send to topic';
    }
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    switch (_target) {
      case MessageTarget.allUsers:
        await _viewModel.sendAllUsersMessage(title: title, body: body);
      case MessageTarget.user:
        await _viewModel.sendUserMessage(
          recipient: _recipientController.text.trim(),
          title: title,
          body: body,
        );
      case MessageTarget.topic:
        await _viewModel.sendTopicMessage(
          topic: _topicController.text.trim(),
          title: title,
          body: body,
        );
    }
  }
}
