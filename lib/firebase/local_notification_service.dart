import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import '../models/app_notification_model.dart';

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'research_updates',
        'Research updates',
        description: 'Notifications about journal and publication trends.',
        importance: Importance.high,
      );

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(settings: initializationSettings);
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
      _isInitialized = true;
    } on MissingPluginException {
      _isInitialized = true;
    }
  }

  Future<void> requestPermission() async {
    await initialize();
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } on MissingPluginException {
      return;
    }
  }

  Future<void> showNotification(AppNotification notification) async {
    await initialize();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.show(
        id: notification.receivedAt.millisecondsSinceEpoch.remainder(100000),
        title: notification.title,
        body: notification.body.isEmpty ? notification.type : notification.body,
        notificationDetails: details,
        payload: notification.type,
      );
    } on MissingPluginException {
      return;
    }
  }
}
