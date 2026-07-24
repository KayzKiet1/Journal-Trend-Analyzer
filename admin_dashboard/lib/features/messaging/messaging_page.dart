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
  final _formKey = GlobalKey<FormState>();
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
            padding: const EdgeInsets.all(28),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _MessagingHeader(),
                          const SizedBox(height: 18),
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
                                : (value) {
                                    setState(() => _target = value.single);
                                  },
                          ),
                          const SizedBox(height: 18),
                          if (_target == MessageTarget.user) ...[
                            TextFormField(
                              controller: _recipientController,
                              decoration: const InputDecoration(
                                labelText: 'User email or uid',
                                prefixIcon: Icon(Icons.person_search_outlined),
                              ),
                              validator: (value) {
                                if (_target != MessageTarget.user) {
                                  return null;
                                }
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nhập email hoặc uid người nhận.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (_target == MessageTarget.topic) ...[
                            TextFormField(
                              controller: _topicController,
                              decoration: const InputDecoration(
                                labelText: 'Topic',
                                hintText: 'announcements',
                                prefixIcon: Icon(Icons.tag_outlined),
                              ),
                              validator: (value) {
                                if (_target != MessageTarget.topic) {
                                  return null;
                                }
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nhập topic cần gửi.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nhập tiêu đề thông báo.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _bodyController,
                            minLines: 4,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Body',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.subject),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nhập nội dung thông báo.';
                              }
                              return null;
                            },
                          ),
                          if (_viewModel.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _ResultBanner.error(_viewModel.errorMessage!),
                          ],
                          if (_successMessage != null) ...[
                            const SizedBox(height: 16),
                            _ResultBanner.success(_successMessage!),
                          ],
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed: _viewModel.isLoading ? null : _send,
                            icon: _viewModel.isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined),
                            label: Text(_buttonLabel),
                          ),
                        ],
                      ),
                    ),
                  ),
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

  String? get _successMessage {
    final lastMessageId = _viewModel.lastMessageId;
    if (lastMessageId != null) {
      return 'Đã gửi thành công. Message ID: $lastMessageId';
    }

    final directResult = _viewModel.lastDirectResult;
    if (directResult != null) {
      return 'Đã gửi tới user: ${directResult['successCount']} thành công, '
          '${directResult['failureCount']} thất bại.';
    }

    return null;
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

    if (mounted && _viewModel.errorMessage == null) {
      _titleController.clear();
      _bodyController.clear();
    }
  }
}

class _MessagingHeader extends StatelessWidget {
  const _MessagingHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.notifications, color: colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Push notification',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tin nhắn được gửi qua Cloud Functions và Firebase Admin SDK.',
                style: theme.textTheme.bodyMedium?.copyWith(
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

class _ResultBanner extends StatelessWidget {
  const _ResultBanner._({required this.message, required this.isError});

  factory _ResultBanner.error(String message) {
    return _ResultBanner._(message: message, isError: true);
  }

  factory _ResultBanner.success(String message) {
    return _ResultBanner._(message: message, isError: false);
  }

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isError
        ? colorScheme.errorContainer
        : const Color(0xFFEAF7EE);
    final foreground = isError
        ? colorScheme.onErrorContainer
        : const Color(0xFF166534);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}
