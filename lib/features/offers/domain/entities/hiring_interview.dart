/// The `interview` of a hiring item (`GET /talent/hiring-offers/{item}`).
///
/// Its [actions] are separate from the item's `available_actions`; the join
/// button follows [canJoin], never an action name.
class HiringInterview {
  const HiringInterview({
    required this.id,
    this.status = '',
    this.statusLabel = '',
    this.start,
    this.end,
    this.minutes,
    this.responseStatus = '',
    this.responseLabel = '',
    this.responseReason,
    this.meetingUrl,
    this.canJoin = false,
    this.actions = const [],
  });
  final String id;

  /// `awaiting_responses`, `awaiting_admin_confirmation`,
  /// `awaiting_reschedule`, `confirmed`, `in_progress`, `completed` or
  /// `cancelled`; [statusLabel] is the backend's text for it.
  final String status, statusLabel;
  final DateTime? start, end;

  /// `duration_minutes`.
  final int? minutes;

  /// The talent's answer (`talent_response`): `pending` until they reply.
  final String responseStatus, responseLabel;
  final String? responseReason;
  final String? meetingUrl;
  final bool canJoin;

  /// `accept_schedule`, `request_schedule_change`, `apologize`.
  final List<String> actions;

  /// `null` when there is no id.
  static HiringInterview? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final id = json['id'];
    if (id == null || '$id'.trim().isEmpty) return null;
    final response = json['talent_response'] is Map
        ? Map<String, dynamic>.from(json['talent_response'] as Map)
        : const <String, dynamic>{};
    final minutes = json['duration_minutes'];
    return HiringInterview(
      id: '$id',
      status: _string(json['status']) ?? '',
      statusLabel: _string(json['status_label']) ?? '',
      start: _date(json['start']),
      end: _date(json['end']),
      minutes: minutes is num ? minutes.toInt() : int.tryParse('$minutes'),
      responseStatus: _string(response['status']) ?? '',
      responseLabel: _string(response['status_label']) ?? '',
      responseReason: _string(response['reason']),
      meetingUrl: _string(json['meeting_url']),
      canJoin: json['can_join'] == true,
      actions: [
        if (json['available_actions'] is List)
          ...(json['available_actions'] as List).whereType<String>(),
      ],
    );
  }
}

String? _string(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;
DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
