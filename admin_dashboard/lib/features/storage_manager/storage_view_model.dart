import 'package:flutter/foundation.dart';

import '../../data/models/storage_file.dart';
import '../../data/repositories/admin_repository.dart';

class StorageViewModel extends ChangeNotifier {
  StorageViewModel({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  final List<StorageFile> _files = [];
  String _nextPageToken = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<StorageFile> get files => List.unmodifiable(_files);

  bool get isLoading => _isLoading;

  bool get hasMore => _nextPageToken.isNotEmpty;

  String? get errorMessage => _errorMessage;

  Future<void> loadFiles({String prefix = '', bool refresh = false}) async {
    await _run(() async {
      if (refresh) {
        _files.clear();
        _nextPageToken = '';
      }

      final result = await _adminRepository.listStorageFiles(
        prefix: prefix,
        pageToken: _nextPageToken.isEmpty ? null : _nextPageToken,
      );
      _files.addAll(result.files);
      _nextPageToken = result.nextPageToken;
    });
  }

  Future<void> deleteFile(String path) async {
    await _run(() async {
      await _adminRepository.deleteStorageFile(path);
      _files.removeWhere((file) => file.name == path);
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
