import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/notifications/notification_badge.dart';
import '../core/notifications/push_notifications.dart';
import '../core/router/app_router.dart';
import '../core/storage/app_preferences.dart';
import 'di/dependencies.dart';
import 'push_navigation.dart';
import '../features/notifications/domain/repositories/device_token_repository.dart';

/// [startPushNotifications] with the registered dependencies.
Future<void> startAppPushNotifications() => startPushNotifications(
  sl<PushNotifications>(),
  badge: sl<NotificationBadge>(),
  devices: sl<DeviceTokenRepository>(),
  preferences: sl<AppPreferences>(),
  onOpened: (message) => openPushTarget(
    AppRouter.router,
    message,
    signedIn: sl<AppPreferences>().isLoggedIn,
  ),
);

/// Push setup at startup: asks for notification permission, refreshes the
/// bell when a push arrives in the foreground, calls [onOpened] for a tapped
/// push (also the one that launched the app), and keeps the backend's copy
/// of this device's FCM token current.
///
/// The token is sent while a talent is signed in: at startup, after every
/// sign-in (the session revision changes) and whenever Firebase rotates
/// it. The same token is not sent twice in one session. Failures are
/// logged (debug builds only) and never block the app; the next start or
/// sign-in tries again.
Future<void> startPushNotifications(
  PushNotifications push, {
  required NotificationBadge badge,
  required DeviceTokenRepository devices,
  required AppPreferences preferences,
  void Function(PushMessage message)? onOpened,
  @visibleForTesting String? platform,
  @visibleForTesting void Function(String message)? log,
}) async {
  final write = log ?? (kDebugMode ? debugPrint : (_) {});
  final os = platform ?? _platform();
  String? token;
  String? sent;

  Future<void> sync() async {
    if (!preferences.isLoggedIn) {
      sent = null;
      return;
    }
    final current = token;
    if (current == null || current == sent) return;
    sent = current;
    final result = await devices.register(current, platform: os);
    result.fold((failure) {
      // Not saved: let the next sign-in or start try again.
      if (sent == current) sent = null;
      write('[FCM] token not saved: ${failure.message}');
    }, (_) {});
  }

  // Debug only: shows what the backend puts in each push, to map taps to
  // screens once its `data` shape is confirmed.
  void logMessage(String event, PushMessage message) => write(
    '[FCM] $event: ${message.title} | data: ${jsonEncode(message.data)}',
  );

  // App-lifetime listeners.
  push.onForegroundMessage.listen((message) {
    logMessage('received', message);
    badge.refresh();
  });
  push.onMessageOpened.listen((message) {
    logMessage('opened', message);
    onOpened?.call(message);
  });
  push.onTokenRefresh.listen((value) {
    write('[FCM] token: $value');
    token = value;
    unawaited(sync());
  });
  preferences.sessionRevision.addListener(() => unawaited(sync()));
  try {
    // Every build asks: without it Android 13+ shows no notifications.
    await push.requestPermission();
    token = await push.token();
    write(token == null ? '[FCM] no token yet' : '[FCM] token: $token');
    await sync();
  } catch (error) {
    write('[FCM] token failed: $error');
  }
  try {
    if (await push.initialMessage() case final message?) {
      logMessage('launched app', message);
      onOpened?.call(message);
    }
  } catch (_) {
    // Logging only; a missing initial message changes nothing.
  }
}

String _platform() {
  if (kIsWeb) return 'web';
  return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
}
