import 'package:flutter/foundation.dart';

import '../../data/repositories/admin_repository.dart';

class MessagingViewModel extends ChangeNotifier {
  MessagingViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _lastMessageId;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get lastMessageId => _lastMessageId;

  Future<void> sendTopicMessage({
    required String topic,
    required String title,
    required String body,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _lastMessageId = null;
    notifyListeners();

    try {
      _lastMessageId = await _adminRepository.sendTopicMessage(
        topic: topic,
        title: title,
        body: body,
      );
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
