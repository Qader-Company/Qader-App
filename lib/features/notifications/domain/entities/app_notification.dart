/// One item of `GET /talent/notifications`.
///
/// [title] and [body] come localized from the backend; the app only reads
/// [type] to decide where a tap leads.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.targetId,
    this.readAt,
    this.createdAt,
  });

  /// UUID; the path parameter of Mark Notification as Read.
  final String id;

  /// A value of `GET /talent/notifications/types`, e.g.
  /// `hiring_interview_proposed`.
  final String type;
  final String title, body;

  /// The record the notification is about (a hiring item for `hiring_*`).
  final String? targetId;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get unread => readAt == null;

  /// `null` when there is no id: such an item cannot be marked as read.
  static AppNotification? fromJson(Map<String, dynamic> json) {
    final id = _text(json['id']);
    if (id.isEmpty) return null;
    final target = json['target_id'];
    return AppNotification(
      id: id,
      type: _text(json['type']),
      title: _text(json['title']),
      body: _text(json['body']),
      targetId: target == null || _text(target).isEmpty ? null : _text(target),
      readAt: _date(json['read_at']),
      createdAt: _date(json['created_at']),
    );
  }

  static String _text(Object? value) => value == null ? '' : '$value'.trim();

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}

/// A page of notifications and its `meta`.
class NotificationPage {
  const NotificationPage({
    required this.items,
    this.page = 1,
    this.lastPage = 1,
    this.total = 0,
  });
  final List<AppNotification> items;
  final int page, lastPage, total;

  factory NotificationPage.fromJson(Map<String, dynamic> data) {
    final raw = data['notifications'];
    final meta = data['meta'] is Map
        ? Map<String, dynamic>.from(data['meta'] as Map)
        : const <String, dynamic>{};
    final items = [
      if (raw is List)
        for (final item in raw)
          if (item is Map)
            if (AppNotification.fromJson(Map<String, dynamic>.from(item))
                case final notification?)
              notification,
    ];
    final page = _int(meta['current_page']) ?? 1;
    return NotificationPage(
      items: items,
      page: page,
      lastPage: _int(meta['last_page']) ?? page,
      total: _int(meta['total']) ?? items.length,
    );
  }

  static int? _int(Object? value) => switch (value) {
    final int number => number,
    final num number => number.toInt(),
    final String text => int.tryParse(text),
    _ => null,
  };
}
