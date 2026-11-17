/// Where an offer stands, one value per designed screen.
///
/// The offers API is not connected yet, so these mirror the Figma frames.
/// Once the backend sends its own status / screen state, follow that.
enum OfferStage {
  awaitingResponse,
  negotiating,
  rejectedByTalent,
  cancelledNoResponse,
  awaitingInterviewTimes,
  interviewInProgress,

  /// The company cancelled the interview; the talent is still in the
  /// interview step, waiting for new times.
  interviewCancelled,

  /// The talent apologized and asked to reschedule; the interview step is
  /// marked failed. The design reuses the company-cancelled copy here.
  interviewApologized,
  contracted;

  /// The Offer / Interview / Accepted step this stage belongs to.
  int get progressStep => switch (this) {
    awaitingResponse ||
    negotiating ||
    rejectedByTalent ||
    cancelledNoResponse => 0,
    awaitingInterviewTimes ||
    interviewInProgress ||
    interviewCancelled ||
    interviewApologized => 1,
    contracted => 2,
  };

  /// The current step failed (offer rejected or cancelled, interview
  /// apologized).
  bool get failed => {
    rejectedByTalent,
    cancelledNoResponse,
    interviewApologized,
  }.contains(this);
}

class OfferCompany {
  const OfferCompany({
    required this.name,
    this.industry = '',
    this.location = '',
    this.website,
  });
  final String name, industry, location;
  final String? website;
}

/// Who wrote a version of the terms.
enum OfferParty { client, talent }

/// One version of the offer's terms (the original or a counter offer).
class OfferTerms {
  const OfferTerms({
    required this.salary,
    required this.currency,
    required this.workMode,
    required this.sentAt,
    required this.by,
    required this.party,
    this.noticeDays,
    this.firstWorkday,
    this.lastWorkday,
    this.workStart,
    this.workEnd,
    this.original = false,
  });

  /// Monthly salary.
  final num salary;

  /// ISO code, e.g. `USD`.
  final String currency;

  /// Backend code, e.g. `remote`, `on_site`, `hybrid`.
  final String workMode;
  final DateTime sentAt;

  /// Name of the recruiter or talent who sent these terms.
  final String by;
  final OfferParty party;
  final int? noticeDays;

  /// `DateTime.weekday` values (1 = Monday … 7 = Sunday).
  final int? firstWorkday, lastWorkday;

  /// Time of day the working hours start and end.
  final Duration? workStart, workEnd;

  /// The client's first offer.
  final bool original;
}

class OfferInterview {
  const OfferInterview({
    required this.start,
    required this.end,
    this.timeZone = '',
    this.meetingUrl,
  });
  final DateTime start, end;

  /// Shown after the time, e.g. `GMT+3`.
  final String timeZone;
  final String? meetingUrl;
  int get minutes => end.difference(start).inMinutes;
}

class OfferContract {
  const OfferContract({
    required this.salary,
    required this.currency,
    required this.workMode,
    required this.workType,
    required this.startDate,
    this.firstWorkday,
    this.lastWorkday,
    this.workStart,
    this.workEnd,
  });
  final num salary;
  final String currency;

  /// Backend codes, e.g. `hybrid`, `on_site` / `full_time`.
  final String workMode, workType;
  final DateTime startDate;
  final int? firstWorkday, lastWorkday;
  final Duration? workStart, workEnd;
}

/// A job offer sent to the talent and where it stands.
class TalentOffer {
  const TalentOffer({
    required this.id,
    required this.company,
    required this.position,
    required this.stage,
    required this.receivedAt,
    required this.terms,
    this.closedAt,
    this.interview,
    this.contract,
    this.noResponseChancesLeft,
  });
  final String id;
  final OfferCompany company;
  final String position;
  final OfferStage stage;
  final DateTime receivedAt;

  /// Every version of the terms, newest first.
  final List<OfferTerms> terms;

  /// When the talent rejected the offer, or Qader closed it.
  final DateTime? closedAt;

  /// The scheduled interview (in progress, or the one that was cancelled).
  final OfferInterview? interview;
  final OfferContract? contract;

  /// No-response warnings left before the account may be suspended.
  final int? noResponseChancesLeft;

  OfferTerms get latest => terms.first;
}
