class AppNotification {
  final String title;
  final String body;
  final String type;
  final DateTime receivedAt;

  const AppNotification({
    required this.title,
    required this.body,
    required this.type,
    required this.receivedAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      title: map['title']?.toString() ?? 'Research update',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'update',
      receivedAt:
          DateTime.tryParse(map['received_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'received_at': receivedAt.toIso8601String(),
    };
  }
}
