import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/app/push_startup.dart';
import 'package:qader/core/notifications/notification_badge.dart';
import 'package:qader/core/notifications/push_notifications.dart';

class _Push implements PushNotifications {
  _Push({this.fail = false});
  final bool fail;
  final refreshes = StreamController<String>.broadcast();
  final messages = StreamController<void>.broadcast();
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
  Stream<void> get onForegroundMessage => messages.stream;

  Future<void> close() async {
    await refreshes.close();
    await messages.close();
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

void main() {
  test('asks permission, logs the token and every rotation', () async {
    final push = _Push();
    final logs = <String>[];
    await startPushNotifications(push, badge: _Badge(), log: logs.add);
    expect(push.calls, ['permission', 'token']);
    push.refreshes.add('rotated');
    await pumpEventQueue();
    expect(logs, ['[FCM] token: first', '[FCM] token: rotated']);
    await push.close();
  });

  test('a push in the foreground refreshes the bell', () async {
    final push = _Push();
    final badge = _Badge();
    await startPushNotifications(push, badge: badge, log: (_) {});
    push.messages
      ..add(null)
      ..add(null);
    await pumpEventQueue();
    expect(badge.refreshes, 2);
    await push.close();
  });

  test('a token failure is logged, not thrown', () async {
    final push = _Push(fail: true);
    final logs = <String>[];
    await startPushNotifications(push, badge: _Badge(), log: logs.add);
    expect(logs.single, contains('token failed'));
    await push.close();
  });
}
