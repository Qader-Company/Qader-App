import 'package:flutter/foundation.dart';
import '../core/notifications/notification_badge.dart';
import '../core/notifications/push_notifications.dart';

/// Push setup at startup: asks for notification permission, refreshes the
/// bell when a push arrives in the foreground, and reads the FCM token.
///
/// No backend endpoint stores the token yet, so for now it is only written
/// to the debug log (debug builds only) to test pushes from the Firebase
/// console. Failures are logged and never block the app.
Future<void> startPushNotifications(
  PushNotifications push, {
  required NotificationBadge badge,
  @visibleForTesting void Function(String message)? log,
}) async {
  final write = log ?? (kDebugMode ? debugPrint : (_) {});
  // App-lifetime listeners.
  push.onForegroundMessage.listen((_) => badge.refresh());
  push.onTokenRefresh.listen((token) => write('[FCM] token: $token'));
  try {
    // Every build asks: without it Android 13+ shows no notifications.
    await push.requestPermission();
    final token = await push.token();
    write(token == null ? '[FCM] no token yet' : '[FCM] token: $token');
  } catch (error) {
    write('[FCM] token failed: $error');
  }
}
