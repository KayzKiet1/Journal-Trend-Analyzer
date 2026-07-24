class CountMetric {
  const CountMetric({required this.name, required this.count});

  final String name;
  final int count;

  factory CountMetric.fromMap(Map<String, dynamic> map) {
    return CountMetric(
      name: map['name']?.toString() ?? '',
      count: _readInt(map['count']),
    );
  }
}

class DailyEventMetric {
  const DailyEventMetric({required this.date, required this.count});

  final String date;
  final int count;

  factory DailyEventMetric.fromMap(Map<String, dynamic> map) {
    return DailyEventMetric(
      date: map['date']?.toString() ?? '',
      count: _readInt(map['count']),
    );
  }
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.days,
    required this.totalEvents,
    required this.activeUsers,
    required this.activeUsersToday,
    required this.activeUsers7d,
    required this.dailyEvents,
    required this.topEvents,
    required this.topJournals,
    required this.generatedAt,
  });

  final int days;
  final int totalEvents;
  final int activeUsers;
  final int activeUsersToday;
  final int activeUsers7d;
  final List<DailyEventMetric> dailyEvents;
  final List<CountMetric> topEvents;
  final List<CountMetric> topJournals;
  final DateTime? generatedAt;

  factory AnalyticsSummary.fromMap(Map<String, dynamic> map) {
    return AnalyticsSummary(
      days: _readInt(map['days']),
      totalEvents: _readInt(map['totalEvents']),
      activeUsers: _readInt(map['activeUsers']),
      activeUsersToday: _readInt(map['activeUsersToday']),
      activeUsers7d: _readInt(map['activeUsers7d']),
      dailyEvents: (map['dailyEvents'] as List<dynamic>? ?? const [])
          .map(
            (item) => DailyEventMetric.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      topEvents: (map['topEvents'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                CountMetric.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      topJournals: (map['topJournals'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                CountMetric.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      generatedAt: DateTime.tryParse(map['generatedAt']?.toString() ?? ''),
    );
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
