import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigValues {
  const RemoteConfigValues({
    required this.maxJournalsDisplay,
    required this.maxKeywordsDisplay,
    required this.enableReportExport,
  });

  final int maxJournalsDisplay;
  final int maxKeywordsDisplay;
  final bool enableReportExport;
}

abstract class RemoteConfigClient {
  Future<RemoteConfigValues> fetchValues();
}

class RemoteConfigService implements RemoteConfigClient {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static const defaultValues = RemoteConfigValues(
    maxJournalsDisplay: 10,
    maxKeywordsDisplay: 10,
    enableReportExport: true,
  );

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<RemoteConfigValues> fetchValues() async {
    await _remoteConfig.setDefaults({
      'max_journals_display': defaultValues.maxJournalsDisplay,
      'max_keywords_display': defaultValues.maxKeywordsDisplay,
      'enable_report_export': defaultValues.enableReportExport,
    });
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ),
    );
    await _remoteConfig.fetchAndActivate();
    return currentValues();
  }

  RemoteConfigValues currentValues() {
    return RemoteConfigValues(
      maxJournalsDisplay: _positiveInt(
        _remoteConfig.getInt('max_journals_display'),
        defaultValues.maxJournalsDisplay,
      ),
      maxKeywordsDisplay: _positiveInt(
        _remoteConfig.getInt('max_keywords_display'),
        defaultValues.maxKeywordsDisplay,
      ),
      enableReportExport: _remoteConfig.getBool('enable_report_export'),
    );
  }

  int _positiveInt(int value, int fallback) {
    return value > 0 ? value : fallback;
  }
}
