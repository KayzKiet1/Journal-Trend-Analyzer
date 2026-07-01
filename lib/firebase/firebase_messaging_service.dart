import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/app_notification_model.dart';

class FirebaseMessagingService {
  FirebaseMessagingService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;
  Stream<RemoteMessage> get openedAppMessages =>
      FirebaseMessaging.onMessageOpenedApp;

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<NotificationSettings> getNotificationSettings() {
    return _messaging.getNotificationSettings();
  }

  Future<String?> getToken() {
    return _messaging.getToken();
  }

  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  Future<void> subscribeToTopic(String topic) {
    return _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) {
    return _messaging.unsubscribeFromTopic(topic);
  }

  Future<RemoteMessage?> getInitialMessage() {
    return _messaging.getInitialMessage();
  }

  AppNotification notificationFromMessage(RemoteMessage message) {
    final notification = message.notification;
    return AppNotification(
      title:
          notification?.title ??
          message.data['title']?.toString() ??
          'Research update',
      body: notification?.body ?? message.data['body']?.toString() ?? '',
      type: message.data['type']?.toString() ?? 'update',
      receivedAt: DateTime.now(),
    );
  }
}
