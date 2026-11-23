import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/resources/theme_manager.dart';
import 'package:qader/features/offers/domain/entities/hiring_offer_details.dart';
import 'package:qader/features/offers/domain/entities/hiring_offer_summary.dart';
import 'package:qader/features/offers/domain/entities/talent_offer.dart';
import 'package:qader/features/offers/domain/repositories/offers_repository.dart';
import 'package:qader/features/offers/presentation/view/live_offer_details_view.dart';

/// The newest `offer` of the Apidog examples; only who sent it, the salary,
/// date and deadline differ between them.
Map<String, dynamic> _offer({
  required int id,
  required String by,
  required String salary,
  required String sentAt,
  String? dueAt,
}) => {
  'id': id,
  'proposed_by': by,
  'salary_amount': salary,
  'currency': {
    'id': 1,
    'code': 'EGP',
    'symbol': 'E£',
    'name': 'Egyptian Pound',
  },
  'work_type': 'full_time',
  'work_mode': 'hybrid',
  'work_start_day': 'sunday',
  'work_end_day': 'thursday',
  'hybrid_work_days': ['thursday'],
  'work_hours': '8',
  'notice_period_days': 30,
  'work_location': 'Cairo, Egypt',
  'status': 'pending',
  'status_label': 'Pending',
  'sent_at': sentAt,
  'response_due_at': dueAt,
  'is_overdue': false,
};

/// `GET /talent/hiring-offers/{item}` Apidog examples. They send the newest
/// `offer` only, without the `offers` history.
Map<String, dynamic> _example(
  Map<String, dynamic> offer,
  List<String> actions,
) => {
  'success': true,
  'data': {
    'id': 7,
    'reference': 'RI-2026-ZHPPYLQH',
    'status': 'offer',
    'status_label': 'Offer',
    'contract_type': 'managed',
    'interview_required': true,
    'company': {'id': 1, 'name': 'Qader Technology', 'logo_url': null},
    'talent': {
      'id': 22,
      'talent_code': 'QDR-2847',
      'job_title': {'id': 10, 'name': 'Backend Developer'},
    },
    'offer': offer,
    'client_decision': null,
    'decision_due_at': null,
    'available_actions': actions,
    'rejection_reason': null,
    'hold_reason': null,
    'cancellation_reason': null,
  },
};

/// "Pending client offer — talent can respond".
Map<String, dynamic> _pendingClient() => _example(
  _offer(
    id: 10,
    by: 'client',
    salary: '25000.0000',
    sentAt: '2026-11-18T08:24:42.000000Z',
    dueAt: '2026-11-20T08:24:42.000000Z',
  ),
  const ['view', 'accept_offer', 'reject_offer', 'counter_offer'],
);

/// "Talent counter offer — waiting for the company".
Map<String, dynamic> _talentCounter() => _example(
  _offer(
    id: 11,
    by: 'talent',
    salary: '27000.0000',
    sentAt: '2026-11-18T09:00:00.000000Z',
  ),
  const ['view'],
);

/// "Expired offer": the company's offer ran out of time.
Map<String, dynamic> _expired() {
  final response = _example(
    _offer(
      id: 10,
      by: 'client',
      salary: '25000.0000',
      sentAt: '2026-11-16T08:24:42.000000Z',
      dueAt: '2026-11-18T08:24:42.000000Z',
    ),
    const ['view'],
  );
  final offer = (response['data'] as Map)['offer'] as Map;
  offer['status'] = 'expired';
  offer['status_label'] = 'Expired';
  return response;
}

/// "Offer accepted — awaiting interview scheduling": no interview yet.
Map<String, dynamic> _awaitingScheduling() {
  final response = _example(
    _offer(
      id: 10,
      by: 'client',
      salary: '25000.0000',
      sentAt: '2026-11-18T08:24:42.000000Z',
      dueAt: '2026-11-20T08:24:42.000000Z',
    ),
    const ['view'],
  );
  final data = response['data'] as Map<String, dynamic>;
  data['status'] = 'interview';
  data['status_label'] = 'Interview';
  (data['offer'] as Map)['status'] = 'accepted';
  (data['offer'] as Map)['status_label'] = 'Accepted';
  data['interview'] = null;
  data['interview_status'] = 'awaiting_scheduling';
  data['interview_status_label'] = 'Awaiting Scheduling';
  return response;
}

/// "Interview stage": offer accepted, an interview time proposed.
Map<String, dynamic> _interview() {
  final response = _example(
    const {
      'id': 10,
      'proposed_by': 'client',
      'salary_amount': '25000.0000',
      'currency': {
        'id': 1,
        'code': 'EGP',
        'symbol': 'E£',
        'name': 'Egyptian Pound',
      },
      'status': 'accepted',
      'status_label': 'Accepted',
      'is_overdue': false,
    },
    const ['view'],
  );
  final data = response['data'] as Map<String, dynamic>;
  data['status'] = 'interview';
  data['status_label'] = 'Interview';
  data['interview'] = {
    'id': 5,
    'status': 'awaiting_responses',
    'status_label': 'Awaiting Responses',
    'start': '2026-11-22T10:00:00.000000Z',
    'end': '2026-11-22T11:00:00.000000Z',
    'duration_minutes': 60,
    'talent_response': {
      'status': 'pending',
      'status_label': 'Pending',
      'reason': null,
      'responded_at': null,
    },
    'meeting_url': null,
    'can_join': false,
    'available_actions': [
      'accept_schedule',
      'request_schedule_change',
      'apologize',
    ],
  };
  return response;
}

/// The closed-stage examples: the item [status] and reasons change; the
/// newest `offer` comes without `sent_at` or the work terms.
Map<String, dynamic> _closed(
  String status,
  String label, {
  required String offerStatus,
  String? holdReason,
  String? rejectionReason,
  String? cancellationReason,
}) {
  final response = _example(
    {
      'id': 10,
      'proposed_by': 'client',
      'salary_amount': '25000.0000',
      'currency': {
        'id': 1,
        'code': 'EGP',
        'symbol': 'E£',
        'name': 'Egyptian Pound',
      },
      'status': offerStatus,
      'status_label':
          '${offerStatus[0].toUpperCase()}${offerStatus.substring(1)}',
      'is_overdue': false,
    },
    const ['view'],
  );
  final data = response['data'] as Map<String, dynamic>;
  data['status'] = status;
  data['status_label'] = label;
  data['hold_reason'] = holdReason;
  data['rejection_reason'] = rejectionReason;
  data['cancellation_reason'] = cancellationReason;
  return response;
}

HiringOfferDetails _details(Map<String, dynamic> response) =>
    HiringOfferDetails.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    )!;

class _Repo extends Fake implements OffersRepository {
  _Repo(this.details);
  final HiringOfferDetails details;
  @override
  Future<Either<Failure, HiringOfferDetails>> loadOffer(String id) async =>
      Right(details);
}

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File(
              '$path/${locale.languageCode}-${locale.countryCode}.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
}

void main() {
  test('without the history, the newest offer is the only version', () {
    final client = _details(_pendingClient());
    expect(client.terms, hasLength(1));
    final terms = client.terms.single;
    expect(terms.party, OfferParty.client);
    expect(terms.original, isTrue);
    expect(terms.salary, 25000);
    expect(terms.currencyId, 1);
    expect(terms.hybridDays, [DateTime.thursday]);
    expect(terms.respondBy, DateTime.utc(2026, 11, 20, 8, 24, 42).toLocal());
    expect(client.latestStatus, 'pending');
    expect(client.latestByTalent, isFalse);
    expect(client.awaitingCompany, isFalse);
    expect(client.allows('accept_offer'), isTrue);
    expect(client.allows('counter_offer'), isTrue);

    final counter = _details(_talentCounter());
    expect(counter.terms.single.party, OfferParty.talent);
    expect(counter.terms.single.salary, 27000);
    expect(counter.terms.single.respondBy, isNull);
    expect(counter.awaitingCompany, isTrue);
    expect(counter.allows('accept_offer'), isFalse);
  });

  test('a list item without the history takes the newest offer', () {
    final item = HiringOfferSummary.fromJson(
      Map<String, dynamic>.from(_talentCounter()['data'] as Map),
    )!;
    expect(item.salary, 27000);
    expect(item.currency, 'EGP');
    expect(item.workMode, 'hybrid');
    expect(item.latestStatus, 'pending');
    expect(item.latestByTalent, isTrue);
  });

  testWidgets('both examples render their terms and the right buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    Future<void> pump(Map<String, dynamic> response) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
          startLocale: const Locale('en', 'US'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _Translations(),
          child: RepositoryProvider<OffersRepository>.value(
            value: _Repo(_details(response)),
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (context, _) => MaterialApp.router(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: ThemeManager.getTheme(context.locale),
                routerConfig: GoRouter(
                  routes: [
                    GoRoute(
                      path: '/',
                      builder: (_, _) =>
                          const LiveOfferDetailsView(offerId: '7'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    // The company's pending offer: its terms and the three answers.
    await pump(_pendingClient());
    expect(find.text('Qader Technology'), findsOneWidget);
    expect(find.textContaining('25,000'), findsWidgets);
    expect(find.textContaining('Cairo, Egypt'), findsOneWidget);
    expect(find.textContaining('Respond by'), findsOneWidget);
    expect(find.text('Accept Offer'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Negotiate'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The talent's counter: its terms, the waiting notice, no buttons.
    await pump(_talentCounter());
    expect(find.textContaining('27,000'), findsWidgets);
    expect(
      find.text(
        'Your counter offer was sent. Waiting for Qader Technology to respond.',
      ),
      findsOneWidget,
    );
    expect(find.text('Accept Offer'), findsNothing);
    expect(find.text('Negotiate'), findsNothing);
    expect(tester.takeException(), isNull);

    // Expired: the banner, the offer marked expired, no buttons.
    await pump(_expired());
    expect(find.text('Offer expired'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.textContaining('25,000'), findsWidgets);
    expect(find.text('Accept Offer'), findsNothing);
    expect(tester.takeException(), isNull);

    // Accepted, no interview yet: the scheduling section and its label.
    await pump(_awaitingScheduling());
    expect(find.text('Waiting for Interview Times'), findsOneWidget);
    expect(find.text('Awaiting Scheduling'), findsOneWidget);
    expect(find.text('Accept Offer'), findsNothing);
    expect(tester.takeException(), isNull);

    // Interview: the proposed time and both statuses from the backend.
    await pump(_interview());
    expect(find.text('Interview'), findsWidgets);
    expect(find.text('Awaiting Responses'), findsOneWidget);
    expect(find.text('Your Response'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('60 min'), findsOneWidget);
    expect(find.textContaining('Nov 22, 2026'), findsOneWidget);
    // No link and `can_join` false: nothing to join yet.
    expect(find.text('Join Interview'), findsNothing);
    expect(find.text('Waiting for Interview Times'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('on hold, rejected, cancelled and completed examples', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    Future<void> pump(Map<String, dynamic> response) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
          startLocale: const Locale('en', 'US'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _Translations(),
          child: RepositoryProvider<OffersRepository>.value(
            value: _Repo(_details(response)),
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (context, _) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: ThemeManager.getTheme(context.locale),
                // A new key per example: a fresh screen and cubit.
                home: LiveOfferDetailsView(key: UniqueKey(), offerId: '7'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    // On hold: the reason, then the accepted offer (no sent date).
    await pump(
      _closed(
        'on_hold',
        'On Hold',
        offerStatus: 'accepted',
        holdReason: 'Waiting for client confirmation.',
      ),
    );
    expect(find.text('Waiting for client confirmation.'), findsOneWidget);
    expect(find.textContaining('25,000'), findsWidgets);
    expect(find.text('Sent'), findsNothing);
    expect(tester.takeException(), isNull);

    // Rejected: banner with the reason, then the last offer.
    await pump(
      _closed(
        'rejected',
        'Rejected',
        offerStatus: 'rejected',
        rejectionReason: 'The client selected another candidate.',
      ),
    );
    expect(find.text('Rejected'), findsWidgets);
    expect(find.text('The client selected another candidate.'), findsOneWidget);
    expect(find.text('Last Offer'), findsOneWidget);
    expect(find.textContaining('25,000'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Cancelled: banner with the reason, then the last offer.
    await pump(
      _closed(
        'cancelled',
        'Cancelled',
        offerStatus: 'pending',
        cancellationReason: 'The hiring request was cancelled.',
      ),
    );
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('The hiring request was cancelled.'), findsOneWidget);
    expect(find.text('Last Offer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // "Accepted item" without an interview step: Offer → Accepted only.
    await pump(
      _closed('accepted', 'Accepted', offerStatus: 'accepted')..update(
        'data',
        (data) => (data as Map)..['interview_required'] = false,
      ),
    );
    expect(find.textContaining('25,000'), findsWidgets);
    expect(find.text('Interview'), findsNothing);
    expect(find.text('Accept Offer'), findsNothing);
    expect(tester.takeException(), isNull);

    // Completed: the accepted offer; no buttons anywhere.
    await pump(_closed('completed', 'Completed', offerStatus: 'accepted'));
    expect(find.textContaining('25,000'), findsWidgets);
    // The progress step and the offer's chip.
    expect(find.text('Accepted'), findsNWidgets(2));
    expect(find.text('Accept Offer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('the interview example is parsed', () {
    final interview = _details(_interview()).interview!;
    expect(interview.id, '5');
    expect(interview.status, 'awaiting_responses');
    expect(interview.start, DateTime.utc(2026, 11, 22, 10).toLocal());
    expect(interview.minutes, 60);
    expect(interview.responseStatus, 'pending');
    expect(interview.canJoin, isFalse);
    expect(interview.meetingUrl, isNull);
    expect(interview.actions, [
      'accept_schedule',
      'request_schedule_change',
      'apologize',
    ]);
    // Without an interview the item still parses.
    expect(_details(_expired()).interview, isNull);
  });
}
