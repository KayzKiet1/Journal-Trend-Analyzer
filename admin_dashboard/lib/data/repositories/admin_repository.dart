import 'package:cloud_functions/cloud_functions.dart';

import '../../core/firebase/firebase_service.dart';
import '../models/admin_user.dart';
import '../models/analytics_summary.dart';
import '../models/audit_log.dart';
import '../models/dashboard_summary.dart';
import '../models/managed_collection.dart';
import '../models/managed_document.dart';
import '../models/storage_file.dart';

class UserListResult {
  const UserListResult({required this.users, required this.nextPageToken});

  final List<AdminUser> users;
  final String nextPageToken;
}

class DocumentListResult {
  const DocumentListResult({
    required this.documents,
    required this.nextPageToken,
  });

  final List<ManagedDocument> documents;
  final String nextPageToken;
}

class StorageFileListResult {
  const StorageFileListResult({
    required this.files,
    required this.nextPageToken,
  });

  final List<StorageFile> files;
  final String nextPageToken;
}

class AuditLogListResult {
  const AuditLogListResult({required this.logs, required this.nextPageToken});

  final List<AuditLog> logs;
  final String nextPageToken;
}

abstract class AdminRepository {
  Future<DashboardSummary> getDashboardSummary();

  Future<AnalyticsSummary> getAnalyticsSummary({int days = 30});

  Future<UserListResult> listUsers({String? pageToken, int maxResults = 50});

  Future<AdminUser> getUser(String uid);

  Future<AdminUser> setUserDisabled({
    required String uid,
    required bool disabled,
  });

  Future<AdminUser> setUserAdminClaim({
    required String uid,
    required bool isAdmin,
  });

  Future<List<ManagedCollection>> listManagedCollections();

  Future<DocumentListResult> listManagedDocuments({
    required String collectionName,
    String? startAfterId,
  });

  Future<ManagedDocument> getManagedDocument({
    required String collectionName,
    required String documentId,
  });

  Future<ManagedDocument> saveManagedDocument({
    required String collectionName,
    required String documentId,
    required Map<String, dynamic> data,
  });

  Future<void> deleteManagedDocument({
    required String collectionName,
    required String documentId,
  });

  Future<Map<String, dynamic>> getAppConfig();

  Future<Map<String, dynamic>> saveAppConfig(Map<String, dynamic> config);

  Future<StorageFileListResult> listStorageFiles({
    String prefix = '',
    String? pageToken,
  });

  Future<void> deleteStorageFile(String path);

  Future<AuditLogListResult> listAuditLogs({String? startAfterId});

  Future<String> sendTopicMessage({
    required String topic,
    required String title,
    required String body,
  });

  Future<Map<String, int>> sendUserMessage({
    required String recipient,
    required String title,
    required String body,
  });

  Future<String> sendAllUsersMessage({
    required String title,
    required String body,
  });
}

class FirebaseAdminRepository implements AdminRepository {
  const FirebaseAdminRepository({FirebaseFunctions? functions})
    : _functions = functions;

  final FirebaseFunctions? _functions;

  FirebaseFunctions get _client => _functions ?? FirebaseService.functions;

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    final data = await _call('getAdminDashboardSummary');
    return DashboardSummary.fromMap(data);
  }

  @override
  Future<AnalyticsSummary> getAnalyticsSummary({int days = 30}) async {
    final data = await _call('getAnalyticsSummary', {'days': days});
    return AnalyticsSummary.fromMap(data);
  }

  @override
  Future<UserListResult> listUsers({
    String? pageToken,
    int maxResults = 50,
  }) async {
    final data = await _call('listUsers', {
      'pageToken': pageToken,
      'maxResults': maxResults,
    });
    final users = (data['users'] as List<dynamic>? ?? const [])
        .map(
          (user) => AdminUser.fromMap(Map<String, dynamic>.from(user as Map)),
        )
        .toList();

    return UserListResult(
      users: users,
      nextPageToken: data['nextPageToken']?.toString() ?? '',
    );
  }

  @override
  Future<AdminUser> getUser(String uid) async {
    final data = await _call('getUser', {'uid': uid});
    return AdminUser.fromMap(Map<String, dynamic>.from(data['user'] as Map));
  }

  @override
  Future<AdminUser> setUserDisabled({
    required String uid,
    required bool disabled,
  }) async {
    final data = await _call('setUserDisabled', {
      'uid': uid,
      'disabled': disabled,
    });
    return AdminUser.fromMap(Map<String, dynamic>.from(data['user'] as Map));
  }

  @override
  Future<AdminUser> setUserAdminClaim({
    required String uid,
    required bool isAdmin,
  }) async {
    final data = await _call('setUserAdminClaim', {
      'uid': uid,
      'isAdmin': isAdmin,
    });
    return AdminUser.fromMap(Map<String, dynamic>.from(data['user'] as Map));
  }

  @override
  Future<List<ManagedCollection>> listManagedCollections() async {
    final data = await _call('listManagedCollections');
    return (data['collections'] as List<dynamic>? ?? const [])
        .map(
          (collection) => ManagedCollection.fromMap(
            Map<String, dynamic>.from(collection as Map),
          ),
        )
        .toList();
  }

  @override
  Future<DocumentListResult> listManagedDocuments({
    required String collectionName,
    String? startAfterId,
  }) async {
    final data = await _call('listManagedDocuments', {
      'collectionName': collectionName,
      'startAfterId': startAfterId,
    });
    final documents = (data['documents'] as List<dynamic>? ?? const [])
        .map(
          (document) => ManagedDocument.fromMap(
            Map<String, dynamic>.from(document as Map),
          ),
        )
        .toList();

    return DocumentListResult(
      documents: documents,
      nextPageToken: data['nextPageToken']?.toString() ?? '',
    );
  }

  @override
  Future<ManagedDocument> getManagedDocument({
    required String collectionName,
    required String documentId,
  }) async {
    final data = await _call('getManagedDocument', {
      'collectionName': collectionName,
      'documentId': documentId,
    });
    return ManagedDocument.fromMap(
      Map<String, dynamic>.from(data['document'] as Map),
    );
  }

  @override
  Future<ManagedDocument> saveManagedDocument({
    required String collectionName,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final result = await _call('saveManagedDocument', {
      'collectionName': collectionName,
      'documentId': documentId,
      'data': data,
    });
    return ManagedDocument.fromMap(
      Map<String, dynamic>.from(result['document'] as Map),
    );
  }

  @override
  Future<void> deleteManagedDocument({
    required String collectionName,
    required String documentId,
  }) async {
    await _call('deleteManagedDocument', {
      'collectionName': collectionName,
      'documentId': documentId,
    });
  }

  @override
  Future<Map<String, dynamic>> getAppConfig() async {
    final data = await _call('getAppConfig');
    return Map<String, dynamic>.from(data['config'] as Map? ?? const {});
  }

  @override
  Future<Map<String, dynamic>> saveAppConfig(
    Map<String, dynamic> config,
  ) async {
    final data = await _call('saveAppConfig', {'config': config});
    return Map<String, dynamic>.from(data['config'] as Map? ?? const {});
  }

  @override
  Future<StorageFileListResult> listStorageFiles({
    String prefix = '',
    String? pageToken,
  }) async {
    final data = await _call('listStorageFiles', {
      'prefix': prefix,
      'pageToken': pageToken,
    });
    final files = (data['files'] as List<dynamic>? ?? const [])
        .map(
          (file) => StorageFile.fromMap(Map<String, dynamic>.from(file as Map)),
        )
        .toList();

    return StorageFileListResult(
      files: files,
      nextPageToken: data['nextPageToken']?.toString() ?? '',
    );
  }

  @override
  Future<void> deleteStorageFile(String path) async {
    await _call('deleteStorageFile', {'path': path});
  }

  @override
  Future<AuditLogListResult> listAuditLogs({String? startAfterId}) async {
    final data = await _call('listAuditLogs', {'startAfterId': startAfterId});
    final logs = (data['logs'] as List<dynamic>? ?? const [])
        .map(
          (log) =>
              AuditLog.fromDocumentMap(Map<String, dynamic>.from(log as Map)),
        )
        .toList();

    return AuditLogListResult(
      logs: logs,
      nextPageToken: data['nextPageToken']?.toString() ?? '',
    );
  }

  @override
  Future<String> sendTopicMessage({
    required String topic,
    required String title,
    required String body,
  }) async {
    final data = await _call('sendTopicMessage', {
      'topic': topic,
      'title': title,
      'body': body,
    });
    return data['messageId']?.toString() ?? '';
  }

  @override
  Future<Map<String, int>> sendUserMessage({
    required String recipient,
    required String title,
    required String body,
  }) async {
    final isEmail = recipient.contains('@');
    final data = await _call('sendUserMessage', {
      if (isEmail) 'email': recipient else 'uid': recipient,
      'title': title,
      'body': body,
    });

    return {
      'successCount': _readInt(data['successCount']),
      'failureCount': _readInt(data['failureCount']),
    };
  }

  @override
  Future<String> sendAllUsersMessage({
    required String title,
    required String body,
  }) async {
    final data = await _call('sendAllUsersMessage', {
      'title': title,
      'body': body,
    });
    return data['messageId']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> _call(
    String functionName, [
    Map<String, dynamic>? parameters,
  ]) async {
    try {
      final callable = _client.httpsCallable(functionName);
      final result = await callable.call<Map<String, dynamic>>(
        parameters ?? const {},
      );
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? error.code);
    }
  }
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
