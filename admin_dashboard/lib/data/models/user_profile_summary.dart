import 'managed_document.dart';

class UserReportFile {
  const UserReportFile({
    required this.name,
    required this.contentType,
    required this.size,
    required this.updated,
    required this.customMetadata,
  });

  final String name;
  final String contentType;
  final int size;
  final String updated;
  final Map<String, dynamic> customMetadata;

  factory UserReportFile.fromMap(Map<String, dynamic> map) {
    return UserReportFile(
      name: map['name']?.toString() ?? '',
      contentType: map['contentType']?.toString() ?? '',
      size: _readInt(map['size']),
      updated: map['updated']?.toString() ?? '',
      customMetadata: Map<String, dynamic>.from(
        map['customMetadata'] as Map? ?? const {},
      ),
    );
  }
}

class UserProfileSummary {
  const UserProfileSummary({
    required this.fcmTokens,
    required this.activity,
    required this.reports,
    required this.savedJournals,
    required this.savedPublications,
  });

  final List<ManagedDocument> fcmTokens;
  final List<ManagedDocument> activity;
  final List<UserReportFile> reports;
  final List<ManagedDocument> savedJournals;
  final List<ManagedDocument> savedPublications;

  factory UserProfileSummary.fromMap(Map<String, dynamic> map) {
    return UserProfileSummary(
      fcmTokens: _documents(map['fcmTokens']),
      activity: _documents(map['activity']),
      reports: (map['reports'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                UserReportFile.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      savedJournals: _documents(map['savedJournals']),
      savedPublications: _documents(map['savedPublications']),
    );
  }

  static List<ManagedDocument> _documents(Object? value) {
    return (value as List<dynamic>? ?? const [])
        .map(
          (item) =>
              ManagedDocument.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
