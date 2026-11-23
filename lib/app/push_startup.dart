import 'package:flutter/foundation.dart';
import '../core/notifications/push_notifications.dart';

/// Asks for notification permission and reads the FCM token at startup.
///
/// No backend endpoint stores the token yet, so for now it is only written
/// to the debug log (debug builds only) to test pushes from the Firebase
/// console. Failures are logged and never block the app.
Future<void> startPushNotifications(
  PushNotifications push, {
  @visibleForTesting void Function(String message)? log,
}) async {
  final write = log ?? (kDebugMode ? debugPrint : null);
  if (write == null) return;
  // App-lifetime listener: the token can rotate while the app runs.
  push.onTokenRefresh.listen((token) => write('[FCM] token: $token'));
  try {
    await push.requestPermission();
    final token = await push.token();
    write(token == null ? '[FCM] no token yet' : '[FCM] token: $token');
  } catch (error) {
    write('[FCM] token failed: $error');
  }
}
