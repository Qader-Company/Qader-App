import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/app/push_startup.dart';
import 'package:qader/core/notifications/push_notifications.dart';

class _Push implements PushNotifications {
  _Push({this.fail = false});
  final bool fail;
  final refreshes = StreamController<String>.broadcast();
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
}

void main() {
  test('asks permission, logs the token and every rotation', () async {
    final push = _Push();
    final logs = <String>[];
    await startPushNotifications(push, log: logs.add);
    expect(push.calls, ['permission', 'token']);
    push.refreshes.add('rotated');
    await pumpEventQueue();
    expect(logs, ['[FCM] token: first', '[FCM] token: rotated']);
    await push.refreshes.close();
  });

  test('a token failure is logged, not thrown', () async {
    final push = _Push(fail: true);
    final logs = <String>[];
    await startPushNotifications(push, log: logs.add);
    expect(logs.single, contains('token failed'));
    await push.refreshes.close();
  });
}
