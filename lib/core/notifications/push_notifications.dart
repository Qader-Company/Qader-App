import 'package:firebase_messaging/firebase_messaging.dart';

/// Push notifications, kept behind an interface so features and tests never
/// depend on Firebase directly.
abstract class PushNotifications {
  /// Asks the user for notification permission (Android 13+ shows a prompt).
  Future<bool> requestPermission();

  /// Registers this device for pushes; the token arrives on [onToken].
  Future<void> register();

  /// Emits the device token the backend needs, on registration and whenever
  /// Firebase rotates it.
  Stream<String> get onToken;
}

/// [PushNotifications] backed by Firebase Cloud Messaging.
class FirebasePushNotifications implements PushNotifications {
  FirebasePushNotifications([FirebaseMessaging? messaging])
    : _messaging = messaging;

  // Resolved lazily so creating this class never touches Firebase before
  // `Firebase.initializeApp` has run.
  final FirebaseMessaging? _messaging;
  FirebaseMessaging get _fcm => _messaging ?? FirebaseMessaging.instance;

  @override
  Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> register() => _fcm.register();

  @override
  Stream<String> get onToken => _fcm.onRegistered;
}
