import 'dart:convert';
import 'dart:typed_data';

import 'admin_repository.dart';

class StorageUploadRequest {
  const StorageUploadRequest({
    required this.bytes,
    required this.fileName,
    required this.contentType,
    this.folder = 'admin_uploads',
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
  final String folder;
}

abstract class StorageRepository {
  Future<String> uploadAdminFile(StorageUploadRequest request);
}

class FirebaseStorageRepository implements StorageRepository {
  FirebaseStorageRepository({AdminRepository? adminRepository})
    : _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final AdminRepository _adminRepository;

  @override
  Future<String> uploadAdminFile(StorageUploadRequest request) async {
    if (request.bytes.isEmpty) {
      throw Exception('Selected file is empty.');
    }

    return _adminRepository.uploadStorageFile(
      base64Data: base64Encode(request.bytes),
      folder: _safeFolder(request.folder),
      fileName: _safeFileName(request.fileName),
      contentType: request.contentType.isEmpty
          ? 'application/octet-stream'
          : request.contentType,
    );
  }

  String _safeFileName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return normalized.isEmpty ? 'upload.bin' : normalized;
  }

  String _safeFolder(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_/-]+'), '_')
        .replaceAll(RegExp(r'/+'), '/')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^/+|/+$'), '');
    return normalized.isEmpty ? 'admin_uploads' : normalized;
  }
}
