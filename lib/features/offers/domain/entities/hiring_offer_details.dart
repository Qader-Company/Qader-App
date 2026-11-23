import 'talent_offer.dart';
import 'hiring_codes.dart';
import 'hiring_interview.dart';

/// `GET /talent/hiring-offers/{item}`: one offer and its terms history.
///
/// Built from the item, its `offers` history (or the newest `offer` when the
/// history is not sent), the newest `offer`'s status and the `interview`;
/// `contract_configuration` is not used yet.
class HiringOfferDetails {
  const HiringOfferDetails({
    required this.id,
    required this.status,
    required this.company,
    this.statusLabel = '',
    this.reference = '',
    this.jobTitle = '',
    this.terms = const [],
    this.hasInterview = false,
    this.interview,
    this.interviewStatusLabel = '',
    this.interviewRequired = true,
    this.latestStatus = '',
    this.latestByTalent = false,
    this.rejectionReason,
    this.holdReason,
    this.cancellationReason,
    this.actions = const [],
  });
  final String id;

  /// Backend code: `pending`, `offer`, `interview`, `accepted`, `on_hold`,
  /// `rejected`, `cancelled` or `completed`.
  final String status;
  final String statusLabel, reference, jobTitle;
  final OfferCompany company;

  /// Every version of the terms, newest first.
  final List<OfferTerms> terms;

  /// `interview` is not null.
  final bool hasInterview;

  /// The parsed `interview`; `null` when absent or without an id.
  final HiringInterview? interview;

  /// `interview_status_label`: the backend's text for where scheduling
  /// stands while there is no [interview] yet, e.g. "Awaiting Scheduling".
  final String interviewStatusLabel;

  /// `interview_required`; without it, accepting goes straight to
  /// `accepted`. Missing means required (the usual flow).
  final bool interviewRequired;

  /// `offer.status` of the newest offer: `pending`, `accepted`,
  /// `rejected` or `expired`. Not the item [status].
  final String latestStatus;

  /// The newest offer is the talent's own counter (`proposed_by`).
  final bool latestByTalent;
  final String? rejectionReason, holdReason, cancellationReason;

  /// `available_actions`: always `view`, plus `accept_offer`,
  /// `reject_offer` and `counter_offer` only while the item is an `offer`
  /// and its newest version is a pending client proposal.
  final List<String> actions;

  /// Whether `available_actions` lets the talent [action] now. Buttons
  /// follow this alone (backend rule), never the status.
  bool allows(String action) => actions.contains(action);

  /// Index of the current step: Offer, Interview, Accepted, or Offer,
  /// Accepted when [interviewRequired] is false.
  int get progressStep {
    final accepted = interviewRequired ? 2 : 1;
    return switch (status) {
      ItemStatus.interview => 1,
      ItemStatus.accepted || ItemStatus.completed => accepted,
      ItemStatus.rejected ||
      ItemStatus.cancelled ||
      ItemStatus.onHold => hasInterview && interviewRequired ? 1 : 0,
      _ => 0,
    };
  }

  /// The client's offer ran out of time; the talent can no longer answer
  /// it until a new offer arrives.
  bool get expired =>
      status == ItemStatus.offer && latestStatus == OfferStatus.expired;

  /// The talent's counter offer waits for the company.
  bool get awaitingCompany =>
      status == ItemStatus.offer &&
      latestStatus == OfferStatus.pending &&
      latestByTalent;

  /// Offer accepted; the company has not proposed interview times yet.
  bool get awaitingInterviewTimes =>
      status == ItemStatus.interview && !hasInterview;

  bool get failed =>
      status == ItemStatus.rejected || status == ItemStatus.cancelled;
  bool get completed => status == ItemStatus.completed;

  /// Parses `data`; `null` when it has no id.
  static HiringOfferDetails? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int && (id is! String || id.isEmpty)) return null;
    final company = _map(json['company']);
    final latest = _map(json['offer']);
    final versions = [
      for (final item in _list(json['offers']))
        if (_map(item) case final raw?)
          if (_terms(raw) case final terms?) terms,
    ]..sort(_newestFirst);
    // Some responses send only the newest `offer`, without the history:
    // it is then the only version (and the one the actions answer).
    if (versions.isEmpty && latest != null) {
      if (_terms(latest) case final terms?) versions.add(terms);
    }
    // The oldest client proposal is the original offer.
    final originalIndex = versions.lastIndexWhere(
      (terms) => terms.party == OfferParty.client,
    );
    return HiringOfferDetails(
      id: '$id',
      status: _string(json['status']) ?? '',
      statusLabel: _string(json['status_label']) ?? '',
      reference: _string(json['reference']) ?? '',
      company: OfferCompany(
        name: _string(company?['name']) ?? '',
        logoUrl: _string(company?['logo_url']),
      ),
      jobTitle:
          _string(_map(_map(json['talent'])?['job_title'])?['name']) ?? '',
      terms: [
        for (var i = 0; i < versions.length; i++)
          i == originalIndex ? _asOriginal(versions[i]) : versions[i],
      ],
      hasInterview: json['interview'] != null,
      interview: HiringInterview.fromJson(json['interview']),
      interviewStatusLabel: _string(json['interview_status_label']) ?? '',
      interviewRequired: json['interview_required'] != false,
      latestStatus: _string(latest?['status']) ?? '',
      latestByTalent: latest?['proposed_by'] == OfferProposer.talent,
      rejectionReason: _string(json['rejection_reason']),
      holdReason: _string(json['hold_reason']),
      cancellationReason: _string(json['cancellation_reason']),
      actions: _list(json['available_actions']).whereType<String>().toList(),
    );
  }

  /// Undated versions go last.
  static int _newestFirst(OfferTerms a, OfferTerms b) =>
      switch ((a.sentAt, b.sentAt)) {
        (final x?, final y?) => y.compareTo(x),
        (null, null) => 0,
        (null, _) => 1,
        (_, null) => -1,
      };

  /// One offer; `null` without a salary or currency. Closed items send
  /// their newest `offer` without `sent_at` or the work terms.
  static OfferTerms? _terms(Map<String, dynamic> raw) {
    final salary = _num(raw['salary_amount']);
    final currency = _string(_map(raw['currency'])?['code']);
    final sentAt = _date(raw['sent_at']) ?? _date(raw['created_at']);
    if (salary == null || currency == null) return null;
    return OfferTerms(
      salary: salary,
      currency: currency,
      workMode: _string(raw['work_mode']) ?? '',
      sentAt: sentAt,
      by: '',
      party: raw['proposed_by'] == OfferProposer.talent
          ? OfferParty.talent
          : OfferParty.client,
      noticeDays: _num(raw['notice_period_days'])?.toInt(),
      firstWorkday: _weekday(raw['work_start_day']),
      lastWorkday: _weekday(raw['work_end_day']),
      hoursPerDay: _num(raw['work_hours']),
      workType: _string(raw['work_type']),
      location: _string(raw['work_location']),
      hybridDays: [
        for (final day in _list(raw['hybrid_work_days']))
          if (_weekday(day) case final weekday?) weekday,
      ],
      statusLabel: _string(raw['status_label']) ?? '',
      respondBy: _date(raw['response_due_at']),
      currencyId: _num(_map(raw['currency'])?['id'])?.toInt(),
    );
  }

  static OfferTerms _asOriginal(OfferTerms terms) => OfferTerms(
    salary: terms.salary,
    currency: terms.currency,
    workMode: terms.workMode,
    sentAt: terms.sentAt,
    by: terms.by,
    party: terms.party,
    noticeDays: terms.noticeDays,
    firstWorkday: terms.firstWorkday,
    lastWorkday: terms.lastWorkday,
    original: true,
    hoursPerDay: terms.hoursPerDay,
    workType: terms.workType,
    location: terms.location,
    hybridDays: terms.hybridDays,
    statusLabel: terms.statusLabel,
    respondBy: terms.respondBy,
    currencyId: terms.currencyId,
  );
}

const _weekdays = {
  'monday': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'friday': DateTime.friday,
  'saturday': DateTime.saturday,
  'sunday': DateTime.sunday,
};

int? _weekday(Object? raw) =>
    raw is String ? _weekdays[raw.trim().toLowerCase()] : null;
Map<String, dynamic>? _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : null;
List<Object?> _list(Object? raw) => raw is List ? raw : const [];
String? _string(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;
num? _num(Object? raw) => raw is num ? raw : num.tryParse('${raw ?? ''}');
DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
