import 'package:flutter/foundation.dart';

/// The unread notifications count shown on the bell in every header.
///
/// Lives in `core` so the shared headers can show it without importing the
/// notifications feature; the app provides the implementation.
abstract class NotificationBadge {
  /// Unread notifications; 0 when signed out or not loaded yet.
  ValueListenable<int> get unreadCount;

  /// Whether the bell opens the notifications screen (a signed-in talent).
  bool get enabled;

  /// Fetches the count again; keeps the last value on failure.
  Future<void> refresh();
}
