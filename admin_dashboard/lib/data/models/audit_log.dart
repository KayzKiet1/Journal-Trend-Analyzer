class AuditLog {
  const AuditLog({
    required this.id,
    required this.adminEmail,
    required this.action,
    required this.target,
    required this.createdAt,
    required this.before,
    required this.after,
  });

  final String id;
  final String adminEmail;
  final String action;
  final String target;
  final String createdAt;
  final Object? before;
  final Object? after;

  factory AuditLog.fromDocumentMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map['data'] as Map? ?? const {});
    return AuditLog(
      id: map['id']?.toString() ?? '',
      adminEmail: data['adminEmail']?.toString() ?? '',
      action: data['action']?.toString() ?? '',
      target: data['target']?.toString() ?? '',
      createdAt: data['createdAt']?.toString() ?? '',
      before: data['before'],
      after: data['after'],
    );
  }
}
