import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/firebase_messaging_service.dart';
import '../models/app_notification_model.dart';

class NotificationPreference {
  final String label;
  final String topic;
  final String description;

  const NotificationPreference({
    required this.label,
    required this.topic,
    required this.description,
  });
}

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel({FirebaseMessagingService? messagingService})
    : _messagingService = messagingService ?? FirebaseMessagingService();

  static const String _notificationsKey = 'fcm_received_notifications';
  static const String _topicsKey = 'fcm_subscribed_topics';
  static const String _notificationsEnabledKey = 'fcm_notifications_enabled';

  static const List<NotificationPreference> preferences = [
    NotificationPreference(
      label: 'Trending research topics',
      topic: 'research_trends',
      description: 'New research topics that are gaining attention.',
    ),
    NotificationPreference(
      label: 'High citation alerts',
      topic: 'citation_alerts',
      description: 'Alerts for publications with high citation counts.',
    ),
    NotificationPreference(
      label: 'Research trend updates',
      topic: 'topic_updates',
      description: 'Updates about changes in research trends.',
    ),
  ];

  final FirebaseMessagingService _messagingService;
  final List<AppNotification> _notifications = [];
  final Set<String> _subscribedTopics = {};
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _isInitialized = false;
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  String _permissionStatus = 'Not determined';
  String? _fcmToken;
  String? _errorMessage;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  Set<String> get subscribedTopics => Set.unmodifiable(_subscribedTopics);
  bool get isLoading => _isLoading;
  String get permissionStatus => _permissionStatus;
  String? get fcmToken => _fcmToken;
  String? get errorMessage => _errorMessage;
  bool get hasToken => _fcmToken != null && _fcmToken!.isNotEmpty;
  bool get isNotificationReady => _permissionStatus == 'Authorized' && hasToken;
  bool get wantsNotifications => _notificationsEnabled && isNotificationReady;
  bool get canRequestPermission => !isLoading && !isNotificationReady;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _setLoading(true);

    try {
      await _loadStoredState();
      await _refreshPermissionAndToken();
      _listenToMessages();
      await _loadInitialMessage();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Could not initialize Firebase Messaging: $error';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> requestPermission() async {
    _setLoading(true);
    try {
      _notificationsEnabled = true;
      final settings = await _messagingService.requestPermission();
      _permissionStatus = _statusLabel(settings.authorizationStatus);
      _fcmToken = await _messagingService.getToken();
      await _saveNotificationsEnabled();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Could not request notification permission: $error';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      await requestPermission();
      return;
    }

    _setLoading(true);
    try {
      _notificationsEnabled = false;
      await _saveNotificationsEnabled();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Could not update notification setting: $error';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setTopicSubscription(String topic, bool enabled) async {
    _setLoading(true);
    try {
      if (enabled) {
        await _messagingService.subscribeToTopic(topic);
        _subscribedTopics.add(topic);
      } else {
        await _messagingService.unsubscribeFromTopic(topic);
        _subscribedTopics.remove(topic);
      }
      await _saveSubscribedTopics();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Could not update topic $topic: $error';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
    notifyListeners();
  }

  String compactToken() {
    final token = _fcmToken;
    if (token == null || token.isEmpty) return 'No token yet';
    if (token.length <= 18) return token;
    return '${token.substring(0, 10)}...${token.substring(token.length - 8)}';
  }

  Future<void> _refreshPermissionAndToken() async {
    final settings = await _messagingService.getNotificationSettings();
    _permissionStatus = _statusLabel(settings.authorizationStatus);
    _fcmToken = await _messagingService.getToken();
  }

  void _listenToMessages() {
    _foregroundSubscription ??= _messagingService.foregroundMessages.listen(
      _addRemoteMessage,
    );
    _openedAppSubscription ??= _messagingService.openedAppMessages.listen(
      _addRemoteMessage,
    );
    _tokenRefreshSubscription ??= _messagingService.tokenRefreshes.listen((
      token,
    ) {
      _fcmToken = token;
      notifyListeners();
    });
  }

  Future<void> _loadInitialMessage() async {
    final initialMessage = await _messagingService.getInitialMessage();
    if (initialMessage != null) {
      await _addRemoteMessage(initialMessage);
    }
  }

  Future<void> _addRemoteMessage(RemoteMessage message) async {
    if (!_notificationsEnabled) return;
    final notification = _messagingService.notificationFromMessage(message);
    _notifications.insert(0, notification);
    if (_notifications.length > 20) {
      _notifications.removeRange(20, _notifications.length);
    }
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> _loadStoredState() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    final storedNotifications = prefs.getStringList(_notificationsKey) ?? [];
    _notifications
      ..clear()
      ..addAll(
        storedNotifications
            .map((value) => jsonDecode(value) as Map<String, dynamic>)
            .map(AppNotification.fromMap),
      );

    _subscribedTopics
      ..clear()
      ..addAll(prefs.getStringList(_topicsKey) ?? []);
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _notificationsKey,
      _notifications
          .map((notification) => jsonEncode(notification.toMap()))
          .toList(),
    );
  }

  Future<void> _saveSubscribedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_topicsKey, _subscribedTopics.toList()..sort());
  }

  Future<void> _saveNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
  }

  String _statusLabel(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return 'Authorized';
      case AuthorizationStatus.denied:
        return 'Denied';
      case AuthorizationStatus.notDetermined:
        return 'Not determined';
      case AuthorizationStatus.provisional:
        return 'Provisional';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }
}
