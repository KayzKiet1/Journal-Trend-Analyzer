import 'package:flutter/foundation.dart';

import '../../data/repositories/admin_repository.dart';

class MessagingViewModel extends ChangeNotifier {
  MessagingViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _lastMessageId;
  String? _lastScheduleId;
  Map<String, int>? _lastDirectResult;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get lastMessageId => _lastMessageId;

  String? get lastScheduleId => _lastScheduleId;

  Map<String, int>? get lastDirectResult => _lastDirectResult;

  Future<void> sendTopicMessage({
    required String topic,
    required String title,
    required String body,
  }) async {
    await _send(() async {
      _lastMessageId = await _adminRepository.sendTopicMessage(
        topic: topic,
        title: title,
        body: body,
      );
    });
  }

  Future<void> sendUserMessage({
    required String recipient,
    required String title,
    required String body,
  }) async {
    await _send(() async {
      _lastDirectResult = await _adminRepository.sendUserMessage(
        recipient: recipient,
        title: title,
        body: body,
      );
    });
  }

  Future<void> sendAllUsersMessage({
    required String title,
    required String body,
  }) async {
    await _send(() async {
      _lastMessageId = await _adminRepository.sendAllUsersMessage(
        title: title,
        body: body,
      );
    });
  }

  Future<void> scheduleNotification({
    required String mode,
    required String recipient,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    await _send(() async {
      _lastScheduleId = await _adminRepository.scheduleNotification(
        mode: mode,
        recipient: recipient,
        title: title,
        body: body,
        scheduledAt: scheduledAt,
      );
    });
  }

  Future<void> _send(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    _lastMessageId = null;
    _lastScheduleId = null;
    _lastDirectResult = null;
    notifyListeners();

    try {
      await action();
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
