import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Called when user taps a notification — provides challengeId and type
  void Function(String challengeId, String type)? onNotificationTap;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final challengeId = message.data['challengeId'] as String? ?? '';
    final type = message.data['type'] as String? ?? '';

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'habitbet_channel',
          'HabitBet Notifications',
          channelDescription: 'Notifications for HabitBet challenges',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: '$challengeId|$type',
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final challengeId = message.data['challengeId'] as String?;
    final type = message.data['type'] as String? ?? '';
    if (challengeId != null && challengeId.isNotEmpty) {
      onNotificationTap?.call(challengeId, type);
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final parts = payload.split('|');
    if (parts.isEmpty || parts[0].isEmpty) return;
    final challengeId = parts[0];
    final type = parts.length > 1 ? parts[1] : '';
    onNotificationTap?.call(challengeId, type);
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'habitbet_channel',
          'HabitBet Notifications',
          channelDescription: 'Notifications for HabitBet challenges',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
