import 'package:flutter/foundation.dart';

import '../../data/models/audit_log.dart';
import '../../data/repositories/admin_repository.dart';

class AuditLogsViewModel extends ChangeNotifier {
  AuditLogsViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  final List<AuditLog> _logs = [];
  String _nextPageToken = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<AuditLog> get logs => List.unmodifiable(_logs);

  bool get isLoading => _isLoading;

  bool get hasMore => _nextPageToken.isNotEmpty;

  String? get errorMessage => _errorMessage;

  Future<void> loadLogs({bool refresh = false}) async {
    await _run(() async {
      if (refresh) {
        _logs.clear();
        _nextPageToken = '';
      }

      final result = await _adminRepository.listAuditLogs(
        startAfterId: _nextPageToken.isEmpty ? null : _nextPageToken,
      );
      _logs.addAll(result.logs);
      _nextPageToken = result.nextPageToken;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
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
