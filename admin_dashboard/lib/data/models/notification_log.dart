class NotificationLog {
  const NotificationLog({
    required this.id,
    required this.mode,
    required this.target,
    required this.targetEmail,
    required this.title,
    required this.body,
    required this.successCount,
    required this.failureCount,
    required this.adminEmail,
    required this.createdAt,
  });

  final String id;
  final String mode;
  final String target;
  final String targetEmail;
  final String title;
  final String body;
  final int successCount;
  final int failureCount;
  final String adminEmail;
  final String createdAt;

  factory NotificationLog.fromDocumentMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map['data'] as Map? ?? const {});
    return NotificationLog(
      id: map['id']?.toString() ?? '',
      mode: data['mode']?.toString() ?? '',
      target: data['target']?.toString() ?? '',
      targetEmail: data['targetEmail']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      successCount: _readInt(data['successCount']),
      failureCount: _readInt(data['failureCount']),
      adminEmail: data['adminEmail']?.toString() ?? '',
      createdAt: data['createdAt']?.toString() ?? '',
    );
  }
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
