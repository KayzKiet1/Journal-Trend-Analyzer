import 'package:flutter/material.dart';

import '../../shared/layouts/admin_shell.dart';
import 'messaging_view_model.dart';

enum MessageTarget { allUsers, user }

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  final _formKey = GlobalKey<FormState>();
  late final MessagingViewModel _viewModel;
  final _recipientController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  MessageTarget _target = MessageTarget.allUsers;
  bool _scheduleLater = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  bool _didApplyDraft = false;

  @override
  void initState() {
    super.initState();
    _viewModel = MessagingViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyDraft) return;
    _didApplyDraft = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      final mode = arguments['mode']?.toString() ?? '';
      final recipient = arguments['recipient']?.toString() ?? '';
      if (mode == 'user') {
        _target = MessageTarget.user;
        _recipientController.text = recipient;
      } else {
        _target = MessageTarget.allUsers;
      }
      _titleController.text = arguments['title']?.toString() ?? '';
      _bodyController.text = arguments['body']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _recipientController.dispose();
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
                                label: Text('Tất cả người dùng'),
                              ),
                              ButtonSegment(
                                value: MessageTarget.user,
                                icon: Icon(Icons.person_outline),
                                label: Text('Một người dùng'),
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
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.send_outlined),
                                label: Text('Gửi ngay'),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.schedule_outlined),
                                label: Text('Lên lịch'),
                              ),
                            ],
                            selected: {_scheduleLater},
                            onSelectionChanged: _viewModel.isLoading
                                ? null
                                : (value) {
                                    setState(
                                      () => _scheduleLater = value.single,
                                    );
                                  },
                          ),
                          if (_scheduleLater) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _viewModel.isLoading
                                      ? null
                                      : _pickDate,
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(_dateLabel),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _viewModel.isLoading
                                      ? null
                                      : _pickTime,
                                  icon: const Icon(Icons.access_time),
                                  label: Text(_timeLabel),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 18),
                          if (_target == MessageTarget.user) ...[
                            TextFormField(
                              controller: _recipientController,
                              decoration: const InputDecoration(
                                labelText: 'Email hoặc UID người nhận',
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
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Tiêu đề',
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
                              labelText: 'Nội dung',
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
    if (_scheduleLater) return 'Lưu lịch gửi';
    switch (_target) {
      case MessageTarget.allUsers:
        return 'Gửi cho tất cả';
      case MessageTarget.user:
        return 'Gửi cho người dùng';
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

    final scheduleId = _viewModel.lastScheduleId;
    if (scheduleId != null) {
      return 'Đã lên lịch gửi thông báo. Schedule ID: $scheduleId';
    }

    return null;
  }

  String get _dateLabel {
    final date = _scheduledDate;
    if (date == null) return 'Chọn ngày';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get _timeLabel {
    final time = _scheduledTime;
    if (time == null) return 'Chọn giờ';
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  DateTime? get _scheduledAt {
    final date = _scheduledDate;
    final time = _scheduledTime;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() => _scheduledDate = selected);
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (selected != null) {
      setState(() => _scheduledTime = selected);
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (_scheduleLater) {
      final scheduledAt = _scheduledAt;
      if (scheduledAt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chọn ngày và giờ gửi thông báo.')),
        );
        return;
      }
      if (scheduledAt.isBefore(
        DateTime.now().add(const Duration(minutes: 1)),
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thời gian gửi phải sau hiện tại ít nhất 1 phút.'),
          ),
        );
        return;
      }

      await _viewModel.scheduleNotification(
        mode: _target == MessageTarget.allUsers ? 'allUsers' : 'user',
        recipient: _target == MessageTarget.user
            ? _recipientController.text.trim()
            : '',
        title: title,
        body: body,
        scheduledAt: scheduledAt,
      );
      if (mounted && _viewModel.errorMessage == null) {
        _titleController.clear();
        _bodyController.clear();
      }
      return;
    }

    switch (_target) {
      case MessageTarget.allUsers:
        await _viewModel.sendAllUsersMessage(title: title, body: body);
      case MessageTarget.user:
        await _viewModel.sendUserMessage(
          recipient: _recipientController.text.trim(),
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
                'Gửi thông báo trực tiếp qua Cloud Functions và Firebase Admin SDK.',
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
