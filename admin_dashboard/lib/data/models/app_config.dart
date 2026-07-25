class RemoteAppConfig {
  const RemoteAppConfig({
    required this.maxJournalsDisplay,
    required this.maxKeywordsDisplay,
    required this.enableReportExport,
  });

  final int maxJournalsDisplay;
  final int maxKeywordsDisplay;
  final bool enableReportExport;

  factory RemoteAppConfig.defaults() {
    return const RemoteAppConfig(
      maxJournalsDisplay: 10,
      maxKeywordsDisplay: 10,
      enableReportExport: true,
    );
  }

  factory RemoteAppConfig.fromMap(Map<String, dynamic> map) {
    return RemoteAppConfig(
      maxJournalsDisplay: _positiveInt(map['maxJournalsDisplay'], 10),
      maxKeywordsDisplay: _positiveInt(map['maxKeywordsDisplay'], 10),
      enableReportExport: map['enableReportExport'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxJournalsDisplay': maxJournalsDisplay,
      'maxKeywordsDisplay': maxKeywordsDisplay,
      'enableReportExport': enableReportExport,
    };
  }

  RemoteAppConfig copyWith({
    int? maxJournalsDisplay,
    int? maxKeywordsDisplay,
    bool? enableReportExport,
  }) {
    return RemoteAppConfig(
      maxJournalsDisplay: maxJournalsDisplay ?? this.maxJournalsDisplay,
      maxKeywordsDisplay: maxKeywordsDisplay ?? this.maxKeywordsDisplay,
      enableReportExport: enableReportExport ?? this.enableReportExport,
    );
  }
}

class RemoteAppConfigResult {
  const RemoteAppConfigResult({required this.config, required this.version});

  final RemoteAppConfig config;
  final RemoteConfigVersion? version;

  factory RemoteAppConfigResult.fromMap(Map<String, dynamic> map) {
    return RemoteAppConfigResult(
      config: RemoteAppConfig.fromMap(
        Map<String, dynamic>.from(map['config'] as Map? ?? const {}),
      ),
      version: map['version'] == null
          ? null
          : RemoteConfigVersion.fromMap(
              Map<String, dynamic>.from(map['version'] as Map),
            ),
    );
  }
}

class RemoteConfigVersion {
  const RemoteConfigVersion({
    required this.versionNumber,
    required this.updateTime,
    required this.updateUserEmail,
    required this.description,
  });

  final String versionNumber;
  final String updateTime;
  final String updateUserEmail;
  final String description;

  factory RemoteConfigVersion.fromMap(Map<String, dynamic> map) {
    return RemoteConfigVersion(
      versionNumber: map['versionNumber']?.toString() ?? '',
      updateTime: map['updateTime']?.toString() ?? '',
      updateUserEmail: map['updateUser'] is Map
          ? (map['updateUser'] as Map)['email']?.toString() ?? ''
          : '',
      description: map['description']?.toString() ?? '',
    );
  }
}

int _positiveInt(Object? value, int fallback) {
  if (value is int && value > 0) return value;
  if (value is num && value > 0) return value.toInt();
  final parsed = int.tryParse(value?.toString() ?? '');
  return parsed != null && parsed > 0 ? parsed : fallback;
}
