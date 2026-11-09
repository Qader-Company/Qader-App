import '../presentation/status_copy.dart';

/// `GET /talent/application`: the talent's application and the screen to show.
class TalentApplication {
  const TalentApplication({
    required this.id,
    required this.status,
    this.statusLabel,
    required this.screenState,
    this.submittedAt,
    this.reviewDecidedAt,
    this.reapplyAt,
    this.canReapply = false,
    this.isBlacklisted = false,
    this.faqs = const [],
    this.interview,
    this.history = const [],
    this.slots = const [],
  });

  final int id;
  final String status;

  /// Backend label for [status], e.g. "Interview Required" (localized by
  /// the `Accept-Language` header).
  final String? statusLabel;

  /// Backend driven screen key, e.g. `under_review`, `interview_slot_required`.
  final String screenState;
  final DateTime? submittedAt;
  final DateTime? reviewDecidedAt;
  final DateTime? reapplyAt;
  final bool canReapply;

  /// `is_blacklisted` / `screen_state: blacklisted`: rejected for good.
  final bool isBlacklisted;
  final List<ApplicationFaq> faqs;

  /// `current_interview`, falling back to `interview`.
  final ApplicationInterview? interview;
  final List<ApplicationInterview> history;

  /// Available slots the talent can choose from (`current_interview.slots`
  /// with `status: available`).
  final List<InterviewSlot> slots;

  /// The status screen for this application, or `null` for "Under Review"
  /// (the home dashboard).
  ApplicationStatus? get viewStatus {
    final hadInterview = interview != null || history.isNotEmpty;
    return switch (screenState) {
      'interview_slot_required' =>
        history.any((entry) => entry.cancelled)
            ? ApplicationStatus.newSlots
            : ApplicationStatus.slots,
      // Interview cancelled and no new slots yet: same "cancelled slots"
      // screen (empty slots card, new slots are being prepared).
      'awaiting_new_interview_slots' ||
      'interview_cancelled' => ApplicationStatus.cancelled,
      // In progress uses the confirmed screen; Join is open (`can_join`).
      'interview_confirmed' ||
      'interview_scheduled' ||
      'interview_in_progress' => ApplicationStatus.confirmed,
      'interview_completed' => ApplicationStatus.completed,
      'accepted' ||
      'talent_accepted' ||
      'approved' => ApplicationStatus.accepted,
      'rejected_after_interview' => ApplicationStatus.rejectedAfterInterview,
      // No dedicated design: the rejected screen without reapply options.
      'blacklisted' =>
        hadInterview
            ? ApplicationStatus.rejectedAfterInterview
            : ApplicationStatus.rejected,
      'rejected' =>
        hadInterview
            ? ApplicationStatus.rejectedAfterInterview
            : ApplicationStatus.rejected,
      _ => null,
    };
  }

  /// Active FAQs meant for the current screen, in display order.
  List<ApplicationFaq> get screenFaqs =>
      faqs
          .where(
            (faq) =>
                faq.screenStates.isEmpty ||
                faq.screenStates.contains(screenState),
          )
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  factory TalentApplication.fromJson(Map<String, dynamic> json) {
    final current = _map(json['current_interview']) ?? _map(json['interview']);
    final interview = current == null
        ? null
        : ApplicationInterview.fromJson(current);
    final topLevelSlots = [
      for (final item in _list(json['available_slots']) ?? const [])
        if (_map(item) case final slot?)
          if (InterviewSlot.fromJson(slot) case final parsed?) parsed,
    ];
    return TalentApplication(
      id: _int(json['id']) ?? 0,
      status:
          _string(json['effective_status']) ?? _string(json['status']) ?? '',
      statusLabel: _string(json['status_label']),
      screenState: _string(json['screen_state']) ?? '',
      submittedAt: _date(json['submitted_at']),
      reviewDecidedAt: _date(json['review_decided_at']),
      reapplyAt: _date(json['reapply_at']),
      canReapply: json['can_reapply'] == true,
      isBlacklisted:
          json['is_blacklisted'] == true ||
          _string(json['screen_state']) == 'blacklisted',
      faqs: [
        for (final item in _list(json['faqs']) ?? const [])
          if (_map(item) case final faq?)
            if (faq['is_active'] != false &&
                _string(faq['question']) != null &&
                _string(faq['answer']) != null)
              ApplicationFaq(
                question: _string(faq['question'])!,
                answer: _string(faq['answer'])!,
                order: _int(faq['display_order']) ?? 0,
                screenStates: [
                  for (final state in _list(faq['screen_states']) ?? const [])
                    if (state is String) state,
                ],
              ),
      ],
      interview: interview,
      // The backend also lists the current interview in the history; the
      // "Interview History" section shows only previous rounds.
      history: [
        for (final item in _list(json['interview_history']) ?? const [])
          if (_map(item) case final entry?)
            if (_int(entry['id']) == null || _int(entry['id']) != interview?.id)
              ApplicationInterview.fromJson(entry),
      ],
      slots:
          (topLevelSlots.isNotEmpty
                  ? topLevelSlots
                  : interview?.slots ?? const <InterviewSlot>[])
              .where((slot) => slot.available)
              .toList(),
    );
  }
}

class ApplicationFaq {
  const ApplicationFaq({
    required this.question,
    required this.answer,
    this.order = 0,
    this.screenStates = const [],
  });
  final String question;
  final String answer;
  final int order;
  final List<String> screenStates;
}

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

Map<String, dynamic>? _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : null;
List<Object?>? _list(Object? raw) => raw is List ? raw : null;
int? _int(Object? raw) => raw is int ? raw : int.tryParse('${raw ?? ''}');
double? _double(Object? raw) =>
    raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}');
String? _string(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;
DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

DateTime? _start(Map<String, dynamic> json) =>
    _date(json['start']) ??
    _date(json['starts_at']) ??
    _date(json['start_at']) ??
    _date(json['scheduled_at']);

DateTime? _end(Map<String, dynamic> json, DateTime start) {
  final end =
      _date(json['end']) ?? _date(json['ends_at']) ?? _date(json['end_at']);
  if (end != null) return end;
  final minutes = _int(json['duration_minutes']);
  return minutes == null ? null : start.add(Duration(minutes: minutes));
}

/// Slots use `mode: online|offline`.
bool _online(Map<String, dynamic> json) {
  final mode = _string(json['mode'])?.toLowerCase();
  if (mode == 'offline') return false;
  if (mode == 'online') return true;
  return _location(json) == null;
}

String? _location(Map<String, dynamic> json) => _string(json['location']);
