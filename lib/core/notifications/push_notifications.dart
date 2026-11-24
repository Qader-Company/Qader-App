import 'package:firebase_messaging/firebase_messaging.dart';

/// One received push: its visible [title] and [body], and the [data] the
/// backend attached for the app (where a tap should lead).
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});
  final String? title, body;
  final Map<String, dynamic> data;
}

/// Push notifications, kept behind an interface so features and tests never
/// depend on Firebase directly.
abstract class PushNotifications {
  /// Asks the user for notification permission (Android 13+ shows a prompt).
  Future<bool> requestPermission();

  /// The FCM registration token the backend sends pushes to; `null` when
  /// Firebase cannot provide one yet.
  Future<String?> token();

  /// Emits a new token whenever Firebase rotates it.
  Stream<String> get onTokenRefresh;

  /// Emits a push that arrives while the app is in the foreground.
  Stream<PushMessage> get onForegroundMessage;

  /// Emits a push the talent tapped while the app was in the background.
  Stream<PushMessage> get onMessageOpened;

  /// The push whose tap launched the app from closed, if any.
  Future<PushMessage?> initialMessage();
}

/// [PushNotifications] backed by Firebase Cloud Messaging.
///
/// Uses the classic registration token rather than v17's `register()`,
/// which returns a Firebase Installation ID for the opt-in "direct send"
/// API: the Firebase console test message and server SDKs send to the
/// registration token.
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
  // ignore: deprecated_member_use
  Future<String?> token() => _fcm.getToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_message);

  @override
  Stream<PushMessage> get onMessageOpened =>
      FirebaseMessaging.onMessageOpenedApp.map(_message);

  @override
  Future<PushMessage?> initialMessage() async {
    final message = await _fcm.getInitialMessage();
    return message == null ? null : _message(message);
  }

  static PushMessage _message(RemoteMessage message) => PushMessage(
    title: message.notification?.title,
    body: message.notification?.body,
    data: Map<String, dynamic>.unmodifiable(message.data),
  );
}
