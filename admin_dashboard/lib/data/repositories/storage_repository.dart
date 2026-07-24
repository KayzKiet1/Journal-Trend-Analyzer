import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/firebase/firebase_service.dart';
import 'admin_repository.dart';

class StorageUploadRequest {
  const StorageUploadRequest({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

abstract class StorageRepository {
  Future<String> uploadAdminFile(StorageUploadRequest request);
}

class FirebaseStorageRepository implements StorageRepository {
  FirebaseStorageRepository({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    AdminRepository? adminRepository,
  }) : _storage = storage ?? FirebaseService.storage,
       _auth = auth ?? FirebaseService.auth,
       _adminRepository = adminRepository ?? const FirebaseAdminRepository();

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final AdminRepository _adminRepository;

  @override
  Future<String> uploadAdminFile(StorageUploadRequest request) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Admin sign-in is required before uploading files.');
    }

    final safeFileName = _safeFileName(request.fileName);
    final path =
        'admin_uploads/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
    final reference = _storage.ref().child(path);
    final metadata = SettableMetadata(
      contentType: request.contentType.isEmpty
          ? 'application/octet-stream'
          : request.contentType,
      customMetadata: {
        'uploadedByUid': user.uid,
        'uploadedByEmail': user.email ?? '',
        'originalFileName': request.fileName,
      },
    );

    await reference.putData(request.bytes, metadata);
    await _adminRepository.recordStorageUpload(
      path: path,
      fileName: request.fileName,
      contentType: request.contentType,
      size: request.bytes.length,
    );

    return path;
  }

  String _safeFileName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return normalized.isEmpty ? 'upload.bin' : normalized;
  }
}
