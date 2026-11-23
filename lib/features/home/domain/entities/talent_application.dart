import 'application_status.dart';

part 'application_interview.dart';

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
