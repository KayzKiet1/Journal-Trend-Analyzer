class SystemHealthItem {
  const SystemHealthItem({
    required this.id,
    required this.path,
    required this.source,
    required this.severity,
    required this.status,
    required this.title,
    required this.message,
    required this.module,
    required this.createdAt,
    required this.data,
  });

  final String id;
  final String path;
  final String source;
  final String severity;
  final String status;
  final String title;
  final String message;
  final String module;
  final String createdAt;
  final Map<String, dynamic> data;

  factory SystemHealthItem.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map['data'] as Map? ?? const {});
    return SystemHealthItem(
      id: map['id']?.toString() ?? '',
      path: map['path']?.toString() ?? '',
      source: map['source']?.toString() ?? '',
      severity: _readString(data, ['severity', 'level', 'type'], 'info'),
      status: _readString(data, ['status'], 'open'),
      title: _readString(data, ['title', 'name', 'reason'], 'Health event'),
      message: _readString(data, ['message', 'error', 'description'], ''),
      module: _readString(data, ['module', 'feature', 'screen'], ''),
      createdAt: data['createdAt']?.toString() ?? '',
      data: data,
    );
  }
}

class SystemHealthSummary {
  const SystemHealthSummary({
    required this.items,
    required this.openIssueCount,
    required this.generatedAt,
  });

  final List<SystemHealthItem> items;
  final int openIssueCount;
  final DateTime? generatedAt;

  factory SystemHealthSummary.fromMap(Map<String, dynamic> map) {
    return SystemHealthSummary(
      items: (map['items'] as List<dynamic>? ?? const [])
          .map(
            (item) => SystemHealthItem.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      openIssueCount: _readInt(map['openIssueCount']),
      generatedAt: DateTime.tryParse(map['generatedAt']?.toString() ?? ''),
    );
  }
}

String _readString(
  Map<String, dynamic> data,
  List<String> keys,
  String defaultValue,
) {
  for (final key in keys) {
    final value = data[key]?.toString();
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }
  return defaultValue;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
