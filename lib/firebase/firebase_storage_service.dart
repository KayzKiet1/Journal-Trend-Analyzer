import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageUploadException implements Exception {
  const StorageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseStorageService {
  FirebaseStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadPdfReport({
    required Uint8List bytes,
    required String fileName,
    required String userId,
    String userEmail = '',
  }) async {
    try {
      final safeUserId = userId.trim().isEmpty ? 'anonymous' : userId.trim();
      final ref = _storage.ref().child('reports/$safeUserId/$fileName');
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'uploadedByUid': safeUserId,
          'uploadedByEmail': userEmail,
          'source': 'mobile_report_export',
        },
      );
      final snapshot = await ref.putData(bytes, metadata);
      return snapshot.ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw StorageUploadException(_formatFirebaseStorageError(error));
    } catch (error) {
      throw StorageUploadException('Khong the upload PDF report: $error');
    }
  }

  String _formatFirebaseStorageError(FirebaseException error) {
    if (error.code == 'unauthorized') {
      return 'Firebase Storage tu choi upload. Hay kiem tra Storage Rules va '
          'dang nhap Firebase truoc khi upload.';
    }

    if (error.code == 'object-not-found') {
      return 'Firebase Storage khong tim thay file sau khi upload. Hay kiem tra '
          'bucket da duoc tao trong Storage, app dang dung dung '
          'google-services.json moi, va thu dang xuat/dang nhap lai.';
    }

    if (error.code == 'quota-exceeded' ||
        error.code == 'bucket-not-found' ||
        error.code == 'project-not-found') {
      return 'Firebase Storage chua san sang cho project nay. Neu dang dung '
          'goi Spark, ban can nang cap Blaze hoac cau hinh bucket Storage hop le.';
    }

    return error.message ?? 'Firebase Storage upload that bai (${error.code}).';
  }
}
