import 'package:flutter/foundation.dart';
import '../../../../core/notifications/notification_badge.dart';
import '../../domain/repositories/notifications_repository.dart';

/// [NotificationBadge] backed by `GET /talent/notifications/unread-count`.
/// App-wide: provided once so every header shares the same count.
class NotificationBadgeController implements NotificationBadge {
  NotificationBadgeController(this._repository, {required this.isSignedIn});
  final NotificationsRepository _repository;

  /// Read on every call: signing in or out does not rebuild this object.
  final bool Function() isSignedIn;
  final _count = ValueNotifier<int>(0);

  /// Only the newest request may set the count.
  int _request = 0;

  @override
  ValueListenable<int> get unreadCount => _count;

  @override
  bool get enabled => isSignedIn();

  @override
  Future<void> refresh() async {
    final request = ++_request;
    if (!enabled) {
      _count.value = 0;
      return;
    }
    final result = await _repository.unreadCount();
    if (request != _request) return;
    result.fold((_) {}, (count) => _count.value = count);
  }

  void dispose() => _count.dispose();
}
