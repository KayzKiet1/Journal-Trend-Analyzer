import 'package:flutter/foundation.dart';

import '../../data/models/notification_log.dart';
import '../../data/repositories/admin_repository.dart';

class NotificationHistoryViewModel extends ChangeNotifier {
  NotificationHistoryViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  final List<NotificationLog> _logs = [];
  String _nextPageToken = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationLog> get logs => List.unmodifiable(_logs);

  bool get isLoading => _isLoading;

  bool get hasMore => _nextPageToken.isNotEmpty;

  String? get errorMessage => _errorMessage;

  Future<void> loadLogs({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (refresh) {
        _logs.clear();
        _nextPageToken = '';
      }

      final result = await _adminRepository.listNotificationLogs(
        startAfterId: _nextPageToken.isEmpty ? null : _nextPageToken,
      );
      _logs.addAll(result.logs);
      _nextPageToken = result.nextPageToken;
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
