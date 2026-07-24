import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';
import 'messaging_view_model.dart';

<<<<<<< Updated upstream
enum MessageTarget { allUsers, user, topic }

=======
/// Trang quản lý gửi thông báo đẩy (Messaging).
/// Cho phép Admin gửi thông báo đến các chủ đề (Topics) cụ thể của Firebase Cloud Messaging.
>>>>>>> Stashed changes
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdminShell(
      title: 'Gửi Thông báo',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(32),
            children: [
              ConstrainedBox(
<<<<<<< Updated upstream
                constraints: const BoxConstraints(maxWidth: 680),
=======
                constraints: const BoxConstraints(maxWidth: 600),
>>>>>>> Stashed changes
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
<<<<<<< Updated upstream
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
=======
                    Text(
                      'Gửi thông báo Push Notification',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thông báo sẽ được gửi đến tất cả người dùng đã đăng ký vào chủ đề này.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                    ),
                    const SizedBox(height: 32),

                    // Nhập chủ đề thông báo.
                    TextField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        labelText: 'Chủ đề (Topic)',
                        hintText: 'ví dụ: announcements, research_updates',
                        prefixIcon: Icon(Icons.tag),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nhập tiêu đề thông báo.
>>>>>>> Stashed changes
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề thông báo',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nhập nội dung thông báo.
                    TextField(
                      controller: _bodyController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung thông báo',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 80),
                          child: Icon(Icons.subject),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        alignLabelWithHint: true,
                      ),
                    ),

                    // Hiển thị lỗi nếu có.
                    if (_viewModel.errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _viewModel.errorMessage!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],

                    // Hiển thị ID tin nhắn cuối cùng gửi thành công.
                    if (_viewModel.lastMessageId != null) ...[
<<<<<<< Updated upstream
                      const SizedBox(height: 12),
                      Text('Sent message id: ${_viewModel.lastMessageId}'),
                    ],
                    if (_viewModel.lastDirectResult != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Sent: ${_viewModel.lastDirectResult!['successCount']} success, '
                        '${_viewModel.lastDirectResult!['failureCount']} failed',
=======
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green),
                            const SizedBox(width: 12),
                            Text(
                              'Đã gửi thành công! ID: ${_viewModel.lastMessageId}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
>>>>>>> Stashed changes
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Nút gửi thông báo.
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _viewModel.isLoading ? null : _send,
                        icon: _viewModel.isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_outlined),
<<<<<<< Updated upstream
                        label: Text(_buttonLabel),
=======
                        label: const Text('Gửi thông báo ngay'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
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
=======
  /// Thực hiện gửi tin nhắn thông qua ViewModel.
  Future<void> _send() async {
    await _viewModel.sendTopicMessage(
      topic: _topicController.text.trim(),
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
    );
    if (mounted && _viewModel.errorMessage == null) {
      _titleController.clear();
      _bodyController.clear();
>>>>>>> Stashed changes
    }
  }
}
