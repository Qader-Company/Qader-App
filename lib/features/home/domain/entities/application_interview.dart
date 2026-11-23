part of 'talent_application.dart';

/// Interview slot as returned by the backend:
/// `{id, mode: online|offline, start, end, location, latitude, longitude,
/// status: available|selected|...}`.
class InterviewSlot {
  const InterviewSlot({
    required this.id,
    required this.start,
    this.end,
    this.online = true,
    this.location,
    this.latitude,
    this.longitude,
    this.status = 'available',
    this.selectable,
  });
  final int id;
  final DateTime start;
  final DateTime? end;
  final bool online;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String status;

  /// Backend `is_selectable`; wins over [status] when present.
  final bool? selectable;

  bool get available => selectable ?? (status.isEmpty || status == 'available');
  bool get isSelected => status == 'selected';

  static InterviewSlot? fromJson(Map<String, dynamic> json) {
    final start = _start(json);
    if (start == null) return null;
    return InterviewSlot(
      id: _int(json['id']) ?? 0,
      start: start,
      end: _end(json, start),
      online: _online(json),
      location: _location(json),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      status: _string(json['status']) ?? '',
      selectable: json['is_selectable'] is bool
          ? json['is_selectable'] as bool
          : null,
    );
  }
}

/// What the talent may do now (`interview.actions`). `null` = not sent.
class InterviewActions {
  const InterviewActions({
    this.canSelectSlot,
    this.canRejectAllSlots,
    this.canCancelAndReschedule,
    this.canJoin,
  });
  final bool? canSelectSlot;
  final bool? canRejectAllSlots;
  final bool? canCancelAndReschedule;
  final bool? canJoin;

  static bool? _flag(Map<String, dynamic>? json, String key) =>
      json?[key] is bool ? json![key] as bool : null;

  factory InterviewActions.fromJson(Map<String, dynamic>? json) =>
      InterviewActions(
        canSelectSlot: _flag(json, 'can_select_slot'),
        canRejectAllSlots: _flag(json, 'can_reject_all_slots'),
        canCancelAndReschedule: _flag(json, 'can_cancel_and_reschedule'),
        canJoin: _flag(json, 'can_join'),
      );
}

/// Interview as returned by the backend:
/// `{id, type: hr|technical|general|final, status, meeting_url, slots: [...]}`.
/// Date, mode and location come from the selected slot.
class ApplicationInterview {
  const ApplicationInterview({
    this.id = 0,
    this.round = 1,
    this.type,
    this.title,
    this.status = '',
    this.statusLabel,
    this.start,
    this.end,
    this.online = true,
    this.location,
    this.latitude,
    this.longitude,
    this.meetingUrl,
    this.slots = const [],
    this.actions = const InterviewActions(),
    this.rejectionsRemaining,
    this.rejectionsMaximum,
    this.rescheduleUsed = false,
    this.completedAt,
    this.joinWindowStart,
    this.joinWindowEnd,
  });
  final int id;
  final int round;

  /// `hr`, `technical`, `general` or `final`.
  final String? type;

  /// Backend label for [type] when provided (`type_label`).
  final String? title;

  /// e.g. `awaiting_slot_selection`, `confirmed`, `completed`, `cancelled`.
  final String status;

  /// Backend label for [status], e.g. "Completed".
  final String? statusLabel;
  final DateTime? start;
  final DateTime? end;
  final bool online;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? meetingUrl;
  final List<InterviewSlot> slots;
  final InterviewActions actions;

  /// `slot_rejections.remaining` / `.maximum`.
  final int? rejectionsRemaining;
  final int? rejectionsMaximum;

  /// `talent_reschedule_used_at` is set: the one reschedule chance is used.
  final bool rescheduleUsed;
  final DateTime? completedAt;

  /// `join_window_starts_at` / `join_window_ends_at`.
  final DateTime? joinWindowStart;
  final DateTime? joinWindowEnd;

  /// Join is open now: backend `can_join`, or the join window has opened
  /// since the response was fetched.
  bool canJoinAt(DateTime now) {
    if (actions.canJoin == true) return true;
    final start = joinWindowStart;
    if (start == null || now.isBefore(start)) return false;
    return joinWindowEnd == null || now.isBefore(joinWindowEnd!);
  }

  bool get completed =>
      completedAt != null || status.contains('complete') || status == 'done';
  bool get cancelled => status.contains('cancel');
  List<InterviewSlot> get availableSlots =>
      slots.where((slot) => slot.available).toList();

  factory ApplicationInterview.fromJson(Map<String, dynamic> json) {
    final slots = [
      for (final item
          in _list(json['slots']) ?? _list(json['available_slots']) ?? const [])
        if (_map(item) case final raw?)
          if (InterviewSlot.fromJson(raw) case final parsed?) parsed,
    ];
    final explicit = _map(json['selected_slot']) ?? _map(json['slot']);
    final selected = explicit != null
        ? InterviewSlot.fromJson(explicit)
        : slots.where((slot) => slot.isSelected).firstOrNull;
    final start = _start(json) ?? selected?.start;
    return ApplicationInterview(
      id: _int(json['id']) ?? 0,
      round: _int(json['round']) ?? _int(json['round_number']) ?? 1,
      type: _string(json['type']),
      title: _string(json['type_label']) ?? _string(json['title']),
      status: _string(json['status']) ?? '',
      statusLabel: _string(json['status_label']),
      start: start,
      end: start == null ? null : _end(json, start) ?? selected?.end,
      online: selected?.online ?? _online(json),
      location: selected?.location ?? _location(json),
      latitude: selected?.latitude ?? _double(json['latitude']),
      longitude: selected?.longitude ?? _double(json['longitude']),
      meetingUrl:
          _string(json['meeting_url']) ??
          _string(json['meeting_link']) ??
          _string(json['join_url']),
      slots: slots,
      actions: InterviewActions.fromJson(_map(json['actions'])),
      rejectionsRemaining: _int(_map(json['slot_rejections'])?['remaining']),
      rejectionsMaximum: _int(_map(json['slot_rejections'])?['maximum']),
      rescheduleUsed: json['talent_reschedule_used_at'] != null,
      completedAt: _date(json['completed_at']),
      joinWindowStart: _date(json['join_window_starts_at']),
      joinWindowEnd: _date(json['join_window_ends_at']),
    );
  }
}
