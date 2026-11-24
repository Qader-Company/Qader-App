import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/app/push_startup.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/notifications/notification_badge.dart';
import 'package:qader/core/notifications/push_notifications.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/notifications/domain/repositories/device_token_repository.dart';

class _Push implements PushNotifications {
  _Push({this.fail = false});
  final bool fail;
  final refreshes = StreamController<String>.broadcast();
  final messages = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();
  PushMessage? launch;
  final calls = <String>[];

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return true;
  }

  @override
  Future<String?> token() async {
    calls.add('token');
    if (fail) throw StateError('no network');
    return 'first';
  }

  @override
  Stream<String> get onTokenRefresh => refreshes.stream;

  @override
  Stream<PushMessage> get onForegroundMessage => messages.stream;

  @override
  Stream<PushMessage> get onMessageOpened => opened.stream;

  @override
  Future<PushMessage?> initialMessage() async => launch;

  Future<void> close() async {
    await refreshes.close();
    await messages.close();
    await opened.close();
  }
}

class _Badge implements NotificationBadge {
  int refreshes = 0;
  @override
  ValueListenable<int> get unreadCount => ValueNotifier(0);
  @override
  bool get enabled => true;
  @override
  Future<void> refresh() async => refreshes++;
}

class _Devices implements DeviceTokenRepository {
  final sent = <String>[];
  Failure? failure;
  @override
  Future<Either<Failure, void>> register(
    String token, {
    required String platform,
  }) async {
    sent.add('$token/$platform');
    if (failure case final failure?) return Left(failure);
    return const Right(null);
  }
}

class _Prefs extends Fake implements AppPreferences {
  _Prefs({this.loggedIn = false});
  bool loggedIn;
  @override
  final sessionRevision = ValueNotifier(0);
  @override
  bool get isLoggedIn => loggedIn;

  void signIn() {
    loggedIn = true;
    sessionRevision.value++;
  }

  void signOut() {
    loggedIn = false;
    sessionRevision.value++;
  }
}

Future<void> _start(
  _Push push, {
  _Badge? badge,
  _Devices? devices,
  _Prefs? prefs,
  List<String>? logs,
}) => startPushNotifications(
  push,
  badge: badge ?? _Badge(),
  devices: devices ?? _Devices(),
  preferences: prefs ?? _Prefs(),
  platform: 'android',
  log: logs?.add ?? (_) {},
);

void main() {
  test('asks permission, logs the token and every rotation', () async {
    final push = _Push();
    final logs = <String>[];
    await _start(push, logs: logs);
    expect(push.calls, ['permission', 'token']);
    push.refreshes.add('rotated');
    await pumpEventQueue();
    expect(logs, ['[FCM] token: first', '[FCM] token: rotated']);
    await push.close();
  });

  test('a push in the foreground refreshes the bell', () async {
    final push = _Push();
    final badge = _Badge();
    await _start(push, badge: badge);
    push.messages
      ..add(const PushMessage())
      ..add(const PushMessage());
    await pumpEventQueue();
    expect(badge.refreshes, 2);
    await push.close();
  });

  test('debug logs show the title and data of each push', () async {
    const message = PushMessage(
      title: 'Interview',
      data: {'type': 'hiring_interview_proposed', 'target_id': '11'},
    );
    final push = _Push()..launch = message;
    final logs = <String>[];
    await _start(push, logs: logs);
    expect(
      logs.last,
      '[FCM] launched app: Interview | data: '
      '{"type":"hiring_interview_proposed","target_id":"11"}',
    );
    push.messages.add(message);
    push.opened.add(message);
    await pumpEventQueue();
    expect(logs[logs.length - 2], startsWith('[FCM] received: Interview'));
    expect(logs.last, startsWith('[FCM] opened: Interview'));
    await push.close();
  });

  test(
    'tapped pushes, and the one that launched the app, are opened',
    () async {
      const launch = PushMessage(data: {'type': 'hiring_offer_received'});
      const tapped = PushMessage(data: {'type': 'hiring_interview_proposed'});
      final push = _Push()..launch = launch;
      final opened = <PushMessage>[];
      await startPushNotifications(
        push,
        badge: _Badge(),
        devices: _Devices(),
        preferences: _Prefs(),
        platform: 'android',
        log: (_) {},
        onOpened: opened.add,
      );
      push.opened.add(tapped);
      // A push received in the foreground is not a tap.
      push.messages.add(const PushMessage());
      await pumpEventQueue();
      expect(opened, [launch, tapped]);
      await push.close();
    },
  );

  test('a token failure is logged, not thrown', () async {
    final push = _Push(fail: true);
    final logs = <String>[];
    await _start(push, logs: logs);
    expect(logs.single, contains('token failed'));
    await push.close();
  });

  test('the token is saved only for a signed-in talent, once per session '
      'and again after a rotation', () async {
    final push = _Push();
    final devices = _Devices();
    final prefs = _Prefs();
    await _start(push, devices: devices, prefs: prefs);
    // Signed out at startup: nothing is sent.
    expect(devices.sent, isEmpty);

    prefs.signIn();
    await pumpEventQueue();
    expect(devices.sent, ['first/android']);

    // Another session change with the same token sends nothing new.
    prefs.sessionRevision.value++;
    await pumpEventQueue();
    expect(devices.sent, hasLength(1));

    push.refreshes.add('rotated');
    await pumpEventQueue();
    expect(devices.sent.last, 'rotated/android');

    // Signing out and in again sends it for the new session.
    prefs.signOut();
    await pumpEventQueue();
    push.refreshes.add('while-signed-out');
    await pumpEventQueue();
    expect(devices.sent, hasLength(2));
    prefs.signIn();
    await pumpEventQueue();
    expect(devices.sent.last, 'while-signed-out/android');
    await push.close();
  });

  test('a signed-in start saves the token; a failure retries later', () async {
    final push = _Push();
    final devices = _Devices()
      ..failure = const NetworkFailure(message: 'offline');
    final prefs = _Prefs(loggedIn: true);
    final logs = <String>[];
    await _start(push, devices: devices, prefs: prefs, logs: logs);
    expect(devices.sent, ['first/android']);
    expect(logs.last, contains('token not saved'));

    devices.failure = null;
    prefs.sessionRevision.value++;
    await pumpEventQueue();
    expect(devices.sent, ['first/android', 'first/android']);
    await push.close();
  });
}
