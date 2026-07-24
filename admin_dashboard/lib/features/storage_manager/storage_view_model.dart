import 'package:flutter/foundation.dart';

import '../../data/models/storage_file.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/storage_repository.dart';

class StorageViewModel extends ChangeNotifier {
  StorageViewModel({
    AdminRepository? adminRepository,
    StorageRepository? storageRepository,
  }) : _adminRepository = adminRepository ?? const FirebaseAdminRepository(),
       _storageRepository = storageRepository ?? FirebaseStorageRepository();

  final AdminRepository _adminRepository;
  final StorageRepository _storageRepository;

  final List<StorageFile> _files = [];
  String _nextPageToken = '';
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _lastUploadedPath;

  List<StorageFile> get files => List.unmodifiable(_files);

  bool get isLoading => _isLoading;

  bool get isUploading => _isUploading;

  bool get hasMore => _nextPageToken.isNotEmpty;

  String? get errorMessage => _errorMessage;

  String? get lastUploadedPath => _lastUploadedPath;

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

  Future<void> uploadFile(StorageUploadRequest request) async {
    _isUploading = true;
    _errorMessage = null;
    _lastUploadedPath = null;
    notifyListeners();

    try {
      _lastUploadedPath = await _storageRepository.uploadAdminFile(request);
      await loadFiles(prefix: 'admin_uploads/', refresh: true);
    } on Exception catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isUploading = false;
      notifyListeners();
    }
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
