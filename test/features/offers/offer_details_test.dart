import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/resources/theme_manager.dart';
import 'package:qader/features/offers/data/repositories/api_offers_repository.dart';
import 'package:qader/features/offers/domain/entities/hiring_offer_details.dart';
import 'package:qader/features/offers/domain/entities/talent_offer.dart';
import 'package:qader/features/offers/domain/repositories/offers_repository.dart';
import 'package:qader/features/offers/presentation/view/live_offer_details_view.dart';
import 'package:qader/features/offers/presentation/widgets/offer_card_skeleton.dart';

/// `GET /talent/hiring-offers/9` test-env response (Apidog, 2026-11-18),
/// without `contract_configuration`, which the app does not read. `offer`
/// (the newest offer) is trimmed to the fields the app reads.
Map<String, dynamic> _offer({
  String status = 'offer',
  String statusLabel = 'Offer',
  String? rejectionReason,
  String latestBy = 'talent',
  String latestStatus = 'pending',
  bool interviewRequired = true,
}) => {
  'success': true,
  'data': {
    'id': 9,
    'reference': 'RI-2026-YQV3VMRE',
    'status': status,
    'status_label': statusLabel,
    'contract_type': 'managed',
    'interview_required': interviewRequired,
    'offer': {'id': 13, 'proposed_by': latestBy, 'status': latestStatus},
    'company': {'id': 1, 'name': 'Qader Technology', 'logo_url': null},
    'talent': {
      'id': 1,
      'talent_code': 'QDR-I29ZFD0M',
      'job_title': {'id': 3, 'name': 'Backend Developer'},
    },
    'offers': [
      {
        'id': 13,
        'proposed_by': 'talent',
        'salary_amount': '25000.0000',
        'currency': {'id': 1, 'code': 'EGP', 'symbol': 'E£'},
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
        'sent_at': '2026-11-18T09:43:18.000000Z',
        'response_due_at': null,
        'is_overdue': false,
        'created_at': '2026-11-18T09:43:18.000000Z',
      },
      {
        'id': 12,
        'proposed_by': 'client',
        'salary_amount': '20000.0000',
        'currency': {'id': 1, 'code': 'EGP', 'symbol': 'E£'},
        'work_type': 'full_time',
        'work_mode': 'hybrid',
        'work_start_day': 'sunday',
        'work_end_day': 'thursday',
        'hybrid_work_days': ['thursday'],
        'work_hours': '8',
        'notice_period_days': 30,
        'work_location': 'Cairo, Egypt',
        'status': 'countered',
        'status_label': 'Countered',
        'sent_at': '2026-11-18T09:41:22.000000Z',
        'response_due_at': '2026-11-20T09:41:22.000000Z',
        'is_overdue': false,
        'created_at': '2026-11-18T09:40:51.000000Z',
      },
    ],
    'interview': null,
    'available_actions': ['view'],
    'rejection_reason': rejectionReason,
    'hold_reason': null,
    'cancellation_reason': null,
    'updated_at': '2026-11-18T09:41:22.000000Z',
  },
};

class _Api extends Fake implements ApiConsumer {
  _Api(this.body);
  final Object? body;
  final paths = <String>[];
  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    paths.add(path);
    return Right(fromJson(body));
  }
}

class _Repo extends Fake implements OffersRepository {
  _Repo(this.results);
  final List<Either<Failure, HiringOfferDetails>> results;
  final ids = <String>[];
  @override
  Future<Either<Failure, HiringOfferDetails>> loadOffer(String id) async {
    ids.add(id);
    return results.length > 1 ? results.removeAt(0) : results.single;
  }
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

HiringOfferDetails _details({
  String status = 'offer',
  String statusLabel = 'Offer',
  String? rejectionReason,
  String latestBy = 'talent',
  String latestStatus = 'pending',
  bool interviewRequired = true,
}) => HiringOfferDetails.fromJson(
  _offer(
        status: status,
        statusLabel: statusLabel,
        rejectionReason: rejectionReason,
        latestBy: latestBy,
        latestStatus: latestStatus,
        interviewRequired: interviewRequired,
      )['data']
      as Map<String, dynamic>,
)!;

void main() {
  test('parses the offer and its history, newest first', () {
    final offer = _details();
    expect(offer.id, '9');
    expect(offer.reference, 'RI-2026-YQV3VMRE');
    expect((offer.status, offer.statusLabel), ('offer', 'Offer'));
    expect(offer.company.name, 'Qader Technology');
    expect(offer.company.logoUrl, isNull);
    expect(offer.jobTitle, 'Backend Developer');
    expect(offer.hasInterview, isFalse);
    expect(offer.actions, ['view']);
    expect(offer.progressStep, 0);
    expect(offer.failed, isFalse);

    final [counter, original] = offer.terms;
    expect(counter.party, OfferParty.talent);
    expect(counter.salary, 25000);
    expect(counter.original, isFalse);
    expect(counter.statusLabel, 'Pending');
    expect(original.party, OfferParty.client);
    expect(original.original, isTrue);
    expect(original.salary, 20000);
    expect(original.currency, 'EGP');
    expect(original.workMode, 'hybrid');
    expect(original.workType, 'full_time');
    expect(original.location, 'Cairo, Egypt');
    expect(original.hoursPerDay, 8);
    expect(original.noticeDays, 30);
    expect(original.firstWorkday, DateTime.sunday);
    expect(original.lastWorkday, DateTime.thursday);
    expect(original.hybridDays, [DateTime.thursday]);
    expect(original.respondBy, DateTime.utc(2026, 11, 20, 9, 41, 22).toLocal());
  });

  test('status maps to the hiring progress', () {
    for (final (status, interview, step, failed) in [
      ('pending', false, 0, false),
      ('interview', true, 1, false),
      ('accepted', true, 2, false),
      ('completed', true, 2, false),
      ('rejected', false, 0, true),
      ('cancelled', true, 1, true),
      ('on_hold', false, 0, false),
    ]) {
      final json = _offer(status: status)['data'] as Map<String, dynamic>;
      json['interview'] = interview ? <String, dynamic>{} : null;
      final offer = HiringOfferDetails.fromJson(json)!;
      expect(offer.progressStep, step, reason: status);
      expect(offer.failed, failed, reason: status);
    }
    expect(HiringOfferDetails.fromJson({'status': 'offer'}), isNull);
  });

  test('backend doc states: waiting, expired, interview, no interview', () {
    final waiting = _details();
    expect(waiting.latestStatus, 'pending');
    expect(waiting.latestByTalent, isTrue);
    expect(waiting.awaitingCompany, isTrue);
    expect(waiting.expired, isFalse);

    final answer = _details(latestBy: 'client');
    expect(answer.awaitingCompany, isFalse);

    final expired = _details(latestBy: 'client', latestStatus: 'expired');
    expect(expired.expired, isTrue);
    expect(expired.awaitingCompany, isFalse);

    // 8.6: the company accepted the talent's counter.
    final interview = _details(status: 'interview', latestStatus: 'accepted');
    expect(interview.awaitingInterviewTimes, isTrue);
    expect(interview.awaitingCompany, isFalse);
    expect(interview.progressStep, 1);

    final direct = _details(
      status: 'accepted',
      latestBy: 'client',
      latestStatus: 'accepted',
      interviewRequired: false,
    );
    expect(direct.interviewRequired, isFalse);
    expect(direct.progressStep, 1);
    // Missing interview_required keeps the usual three steps.
    final json = _offer()['data'] as Map<String, dynamic>
      ..remove('interview_required')
      ..remove('offer');
    final bare = HiringOfferDetails.fromJson(json)!;
    expect(bare.interviewRequired, isTrue);
    expect(bare.awaitingCompany, isFalse);
  });

  test('repository loads /talent/hiring-offers/{id}', () async {
    final api = _Api(_offer());
    final result = await ApiOffersRepository(api).loadOffer('9');
    expect(api.paths, ['/talent/hiring-offers/9']);
    expect(result.getOrThrow().terms, hasLength(2));
    for (final body in [
      null,
      {'success': true, 'data': null},
      {
        'success': true,
        'data': {'status': 'offer'},
      },
    ]) {
      final invalid = await ApiOffersRepository(_Api(body)).loadOffer('9');
      expect(invalid.getErrorOrThrow().message, 'offers_invalid_response');
    }
  });

  testWidgets('live details show the history, a rejection and a retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final family in ['Poppins', 'Rubik']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();

    final captureKey = GlobalKey();
    Future<void> pump(_Repo repo) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: EasyLocalization(
            supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
            startLocale: const Locale('en', 'US'),
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: const _Translations(),
            child: RepositoryProvider<OffersRepository>.value(
              value: repo,
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
                            const LiveOfferDetailsView(offerId: '9'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final repo = _Repo([Right(_details())]);
    await pump(repo);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(repo.ids.first, '9');
    expect(find.byType(OfferDetailsSkeleton), findsNothing);
    expect(find.text('Qader Technology'), findsOneWidget);
    expect(find.text('Talent Offer'), findsOneWidget);
    expect(find.text('Client Offer'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Your counter offer'), findsOneWidget);
    expect(find.text('Proposed by the company'), findsOneWidget);
    expect(find.textContaining('Respond by'), findsOneWidget);
    expect(find.textContaining('8 hours / day'), findsNWidgets(2));
    expect(find.textContaining('Cairo, Egypt'), findsNWidgets(2));
    expect(
      find.text(
        'Your counter offer was sent. Waiting for Qader Technology to respond.',
      ),
      findsOneWidget,
    );
    // The newest version is the talent's own counter, so the backend
    // sends only "view": no buttons until the company answers.
    expect(find.text('Accept Offer'), findsNothing);
    expect(find.text('Negotiate'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/design_review/offer_details_live.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });

    final rejected = _Repo([
      const Left(NetworkFailure(message: 'offline')),
      Right(
        _details(
          status: 'rejected',
          statusLabel: 'Rejected',
          rejectionReason: 'The position was filled.',
        ),
      ),
    ]);
    await pump(rejected);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text("We couldn't load this offer."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('The position was filled.'), findsOneWidget);
    // As in Figma: banner under the progress, then only the last offer.
    expect(
      tester.getTopLeft(find.text('Rejected')).dy,
      greaterThan(tester.getTopLeft(find.text('Hiring Progress')).dy),
    );
    expect(find.text('Last Offer'), findsOneWidget);
    expect(find.text('Talent Offer'), findsOneWidget); // its chip
    expect(find.text('Client Offer'), findsNothing);
    expect(tester.takeException(), isNull);

    Future<void> capture(String name) => tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/design_review/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });

    Future<void> show(HiringOfferDetails details) async {
      await pump(_Repo([Right(details)]));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    // Offer 9 now: counter accepted, no interview yet (Figma frame).
    await show(_details(status: 'interview', latestStatus: 'accepted'));
    expect(find.text('Waiting for Interview Times'), findsOneWidget);
    expect(find.text('Talent Offer'), findsNothing);
    expect(find.text('Client Offer'), findsNothing);
    await capture('offer_details_live_interview');

    await show(_details(latestBy: 'client', latestStatus: 'expired'));
    expect(find.text('Offer expired'), findsOneWidget);
    expect(find.text('Accept Offer'), findsNothing);
    await capture('offer_details_live_expired');

    await show(
      _details(
        status: 'accepted',
        latestBy: 'client',
        latestStatus: 'accepted',
        interviewRequired: false,
      ),
    );
    expect(find.text('Interview'), findsNothing);
    expect(find.text('Accepted'), findsWidgets);
    await capture('offer_details_live_no_interview');

    await show(
      _details(
        status: 'rejected',
        statusLabel: 'Rejected',
        rejectionReason: 'The position was filled.',
        latestStatus: 'rejected',
      ),
    );
    await capture('offer_details_live_rejected');
  });
}
