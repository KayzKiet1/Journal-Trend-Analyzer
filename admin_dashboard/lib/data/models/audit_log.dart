class AuditLog {
  const AuditLog({
    required this.id,
    required this.action,
    required this.actorId,
  });

  final String id;
  final String action;
  final String actorId;
}
