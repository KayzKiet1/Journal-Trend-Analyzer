class StorageFile {
  const StorageFile({
    required this.name,
    required this.bucket,
    required this.contentType,
    required this.size,
    required this.updated,
    required this.viewUrl,
    required this.downloadUrl,
    required this.customMetadata,
  });

  final String name;
  final String bucket;
  final String contentType;
  final int size;
  final String updated;
  final String viewUrl;
  final String downloadUrl;
  final Map<String, dynamic> customMetadata;

  String get uploadedByEmail =>
      customMetadata['uploadedByEmail']?.toString() ?? '';

  String get uploadedByUid => customMetadata['uploadedByUid']?.toString() ?? '';

  String get originalFileName =>
      customMetadata['originalFileName']?.toString() ?? fileName;

  String get folder {
    final explicitFolder = customMetadata['folder']?.toString() ?? '';
    if (explicitFolder.isNotEmpty) {
      return explicitFolder;
    }

    final segments = name.split('/');
    return segments.isEmpty ? '' : segments.first;
  }

  String get ownerLabel {
    if (uploadedByEmail.isNotEmpty) {
      return uploadedByEmail;
    }
    if (uploadedByUid.isNotEmpty) {
      return uploadedByUid;
    }

    final segments = name.split('/');
    if (segments.length >= 2) {
      return segments[1];
    }

    return 'Unknown uploader';
  }

  String get fileName {
    final segments = name.split('/');
    return segments.isEmpty ? name : segments.last;
  }

  bool get isImage => contentType.startsWith('image/');

  String get effectiveViewUrl => viewUrl.isNotEmpty ? viewUrl : downloadUrl;

  String get effectiveDownloadUrl =>
      downloadUrl.isNotEmpty ? downloadUrl : viewUrl;

  factory StorageFile.fromMap(Map<String, dynamic> map) {
    return StorageFile(
      name: map['name']?.toString() ?? '',
      bucket: map['bucket']?.toString() ?? '',
      contentType: map['contentType']?.toString() ?? '',
      size: _readInt(map['size']),
      updated: map['updated']?.toString() ?? '',
      viewUrl: map['viewUrl']?.toString() ?? '',
      downloadUrl: map['downloadUrl']?.toString() ?? '',
      customMetadata: Map<String, dynamic>.from(
        map['customMetadata'] as Map? ?? const {},
      ),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
