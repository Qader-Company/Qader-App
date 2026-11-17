import '../../domain/entities/talent_offer.dart';

/// Sample offers, one per designed screen, until the offers API is
/// connected. Preview data only: never real account data.
abstract final class OffersPreviewData {
  static const _company = OfferCompany(
    name: 'TechCorp',
    industry: 'Technology & Software',
    location: 'Riyadh, Saudi Arabia',
    website: 'https://www.techcorp.com',
  );
  static const _recruiter = 'Mostafa Ali';
  static const _talent = 'Muhamed Bayomee';

  static OfferTerms _client(num salary, {bool original = false}) => OfferTerms(
    salary: salary,
    currency: 'USD',
    workMode: 'remote',
    noticeDays: 15,
    sentAt: DateTime(2026, 11, 10, 14, 30),
    firstWorkday: DateTime.sunday,
    lastWorkday: DateTime.thursday,
    workStart: const Duration(hours: 9),
    workEnd: const Duration(hours: 18),
    by: _recruiter,
    party: OfferParty.client,
    original: original,
  );

  static final _original = _client(6500, original: true);
  static final _counter = _client(7200);
  static final _talentCounter = OfferTerms(
    salary: 7500,
    currency: 'USD',
    workMode: 'remote',
    noticeDays: 15,
    sentAt: DateTime(2026, 11, 11, 10),
    firstWorkday: DateTime.sunday,
    lastWorkday: DateTime.thursday,
    workStart: const Duration(hours: 9),
    workEnd: const Duration(hours: 18),
    by: _talent,
    party: OfferParty.talent,
  );

  static TalentOffer _offer(
    String id,
    OfferStage stage, {
    String position = 'Senior Frontend Developer',
    required DateTime receivedAt,
    List<OfferTerms>? terms,
    DateTime? closedAt,
    OfferInterview? interview,
    OfferContract? contract,
    int? noResponseChancesLeft,
  }) => TalentOffer(
    id: id,
    company: _company,
    position: position,
    stage: stage,
    receivedAt: receivedAt,
    terms: terms ?? [_original],
    closedAt: closedAt,
    interview: interview,
    contract: contract,
    noResponseChancesLeft: noResponseChancesLeft,
  );

  static final offers = [
    _offer(
      '1',
      OfferStage.awaitingResponse,
      receivedAt: DateTime(2026, 11, 14),
    ),
    _offer(
      '2',
      OfferStage.negotiating,
      position: 'Frontend Team Lead',
      receivedAt: DateTime(2026, 11, 12),
      terms: [_client(6500), _talentCounter, _original],
    ),
    _offer(
      '3',
      OfferStage.awaitingInterviewTimes,
      position: 'React Developer',
      receivedAt: DateTime(2026, 11, 3),
    ),
    _offer(
      '4',
      OfferStage.interviewInProgress,
      position: 'Senior UI Engineer',
      receivedAt: DateTime(2026, 10, 28),
      interview: OfferInterview(
        start: DateTime(2026, 7, 2, 10),
        end: DateTime(2026, 7, 2, 11),
        timeZone: 'GMT+3',
        meetingUrl: 'https://meet.example.com/ftvdsguchbsaihckhnl',
      ),
    ),
    _offer(
      '5',
      OfferStage.interviewCancelled,
      position: 'Web Developer',
      receivedAt: DateTime(2026, 10, 20),
      interview: OfferInterview(
        start: DateTime(2026, 9, 1, 11),
        end: DateTime(2026, 9, 1, 12),
        timeZone: 'GMT+3',
      ),
    ),
    _offer(
      '9',
      OfferStage.interviewApologized,
      position: 'UI Developer',
      receivedAt: DateTime(2026, 10, 10),
      interview: OfferInterview(
        start: DateTime(2026, 9, 1, 11),
        end: DateTime(2026, 9, 1, 12),
        timeZone: 'GMT+3',
      ),
    ),
    _offer(
      '6',
      OfferStage.contracted,
      position: 'Frontend Engineer',
      receivedAt: DateTime(2026, 9, 15),
      contract: OfferContract(
        salary: 8500,
        currency: 'USD',
        workMode: 'hybrid',
        workType: 'full_time',
        startDate: DateTime(2026, 9, 25),
        firstWorkday: DateTime.sunday,
        lastWorkday: DateTime.thursday,
        workStart: const Duration(hours: 9),
        workEnd: const Duration(hours: 18),
      ),
    ),
    _offer(
      '7',
      OfferStage.rejectedByTalent,
      position: 'JavaScript Developer',
      receivedAt: DateTime(2026, 8, 18),
      terms: [_counter, _original],
      closedAt: DateTime(2026, 8, 22),
    ),
    _offer(
      '8',
      OfferStage.cancelledNoResponse,
      position: 'Frontend Developer',
      receivedAt: DateTime(2026, 8, 25),
      terms: [_counter, _original],
      closedAt: DateTime(2026, 8, 30),
      noResponseChancesLeft: 1,
    ),
  ];

  static TalentOffer? byId(String id) {
    for (final offer in offers) {
      if (offer.id == id) return offer;
    }
    return null;
  }
}
