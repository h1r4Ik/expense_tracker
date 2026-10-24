import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service responsible for dispatching OS / System-level notifications in the notification tray
class SystemNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Android notification channel details
  static const String channelId = 'hermes_ledger_notifications';
  static const String channelName = 'Hermes Ledger Updates';
  static const String channelDescription =
      'Real-time notifications for shared group expenses, updates, and reminders';

  /// Initialize system notification plugin and set up channel
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Create high-importance Android notification channel
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        // Request runtime notification permission (Android 13+ / API 33+)
        await androidImplementation?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e, stack) {
      debugPrint('Failed to initialize SystemNotificationService: $e\n$stack');
    }
  }

  /// Display a native system notification in the device notification shade
  static Future<void> show({
    required String title,
    required String message,
    int? id,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final notificationId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Hermes Notification',
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: notificationId,
        title: title,
        body: message,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e, stack) {
      debugPrint('Error showing system notification: $e\n$stack');
    }
  }
}
