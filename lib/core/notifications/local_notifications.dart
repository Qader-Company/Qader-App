import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'push_notifications.dart';

/// Notifications the app shows itself: Firebase shows a push on its own
/// only while the app is in the background, so a push that arrives while
/// the app is open is shown through this, on the app's channel.
abstract class LocalNotifications {
  /// Creates the channel and registers [onTap], which receives the push
  /// data of a tapped notification.
  Future<void> init({required void Function(Map<String, dynamic>) onTap});

  /// Shows [message] as a heads-up notification.
  Future<void> show(PushMessage message);

  /// The push data of the notification whose tap launched the app, if any.
  Future<Map<String, dynamic>?> launchData();
}

/// [LocalNotifications] backed by `flutter_local_notifications`.
class PluginLocalNotifications implements LocalNotifications {
  PluginLocalNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin _plugin;

  /// Also named in AndroidManifest.xml as Firebase's default channel, so
  /// background pushes pop up the same way.
  static const channelId = 'qader_notifications';
  static const _channel = AndroidNotificationChannel(
    channelId,
    'Qader',
    importance: Importance.high,
  );

  @override
  Future<void> init({
    required void Function(Map<String, dynamic>) onTap,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap(_decode(response.payload)),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  @override
  Future<void> show(PushMessage message) => _plugin.show(
    id: message.hashCode & 0x7fffffff,
    title: message.title,
    body: message.body,
    payload: jsonEncode(message.data),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );

  @override
  Future<Map<String, dynamic>?> launchData() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return _decode(details.notificationResponse?.payload);
  }

  static Map<String, dynamic> _decode(String? payload) {
    if (payload == null || payload.isEmpty) return const {};
    try {
      final value = jsonDecode(payload);
      return value is Map ? Map<String, dynamic>.from(value) : const {};
    } on FormatException {
      debugPrint('[FCM] bad notification payload');
      return const {};
    }
  }
}
