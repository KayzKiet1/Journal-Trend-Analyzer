class StorageFile {
  const StorageFile({
    required this.name,
    required this.bucket,
    required this.contentType,
    required this.size,
    required this.updated,
    required this.downloadUrl,
    required this.customMetadata,
  });

  final String name;
  final String bucket;
  final String contentType;
  final int size;
  final String updated;
  final String downloadUrl;
  final Map<String, dynamic> customMetadata;

  String get uploadedByEmail =>
      customMetadata['uploadedByEmail']?.toString() ?? '';

  String get uploadedByUid => customMetadata['uploadedByUid']?.toString() ?? '';

  bool get isImage => contentType.startsWith('image/');

  factory StorageFile.fromMap(Map<String, dynamic> map) {
    return StorageFile(
      name: map['name']?.toString() ?? '',
      bucket: map['bucket']?.toString() ?? '',
      contentType: map['contentType']?.toString() ?? '',
      size: _readInt(map['size']),
      updated: map['updated']?.toString() ?? '',
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
