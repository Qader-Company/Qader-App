import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
import 'package:qader/features/offers/domain/entities/counter_offer.dart';
import 'package:qader/features/offers/domain/entities/hiring_offer_details.dart';
import 'package:qader/features/offers/domain/repositories/offers_repository.dart';
import 'package:qader/features/offers/presentation/cubit/offer_details_cubit.dart';
import 'package:qader/features/offers/presentation/view/live_offer_details_view.dart';

/// Trimmed Get Hiring Offer response (Apidog) whose newest version is the
/// client's, so the talent can answer it.
Map<String, dynamic> _offer({
  String status = 'offer',
  List<String> actions = const ['view'],
}) => {
  'id': 9,
  'status': status,
  'status_label': status,
  'company': {'id': 1, 'name': 'Qader Technology', 'logo_url': null},
  'talent': {
    'job_title': {'id': 3, 'name': 'Backend Developer'},
  },
  'offers': [
    {
      'id': 12,
      'proposed_by': 'client',
      'salary_amount': '20000.0000',
      'currency': {'id': 1, 'code': 'EGP'},
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
      'sent_at': '2026-11-18T09:41:22.000000Z',
    },
  ],
  'interview': null,
  'available_actions': actions,
};

class _Api extends Fake implements ApiConsumer {
  Object? reply = {'success': true, 'message': 'api.updated'};
  final posts = <(String, Object?, String?)>[];
  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic json) fromJson,
  }) async {
    posts.add((path, data, contentType));
    return Right(fromJson(reply));
  }
}

class _Repo extends Fake implements OffersRepository {
  _Repo(this.actions);
  List<String> actions;
  String status = 'offer';
  final calls = <String>[];
  CounterOffer? countered;
  Failure? failure;
  int loads = 0;

  @override
  Future<Either<Failure, HiringOfferDetails>> loadOffer(String id) async {
    loads++;
    return Right(
      HiringOfferDetails.fromJson(_offer(status: status, actions: actions))!,
    );
  }

  Either<Failure, void> _done(String call) {
    calls.add(call);
    if (failure case final failure?) return Left(failure);
    // As on the server: once answered, the item leaves `offer`.
    actions = const ['view'];
    status = 'interview';
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> accept(String id) async => _done('accept $id');

  @override
  Future<Either<Failure, void>> reject(String id) async => _done('reject $id');

  @override
  Future<Either<Failure, void>> counter(String id, CounterOffer offer) async {
    countered = offer;
    return _done('counter $id');
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

/// The three answers the backend adds while a client offer is pending.
const _answer = ['accept_offer', 'reject_offer', 'counter_offer'];

void main() {
  test(
    'actions post to their endpoints; counter sends the JSON body',
    () async {
      final api = _Api();
      final repository = ApiOffersRepository(api);
      expect((await repository.accept('9')).isSuccess, isTrue);
      expect((await repository.reject('9')).isSuccess, isTrue);
      final details = HiringOfferDetails.fromJson(_offer())!;
      final base = details.terms.single;
      expect(base.currencyId, 1);
      await repository.counter(
        '9',
        CounterOffer(
          salary: 25000,
          currencyId: base.currencyId,
          workType: base.workType,
          workMode: 'hybrid',
          firstWorkday: base.firstWorkday,
          lastWorkday: base.lastWorkday,
          hybridDays: const [DateTime.thursday],
          hoursPerDay: base.hoursPerDay,
          noticeDays: 30,
          location: 'Cairo, Egypt',
        ),
      );
      expect(api.posts.map((post) => post.$1), [
        '/talent/hiring-offers/9/accept',
        '/talent/hiring-offers/9/reject',
        '/talent/hiring-offers/9/counter',
      ]);
      expect(api.posts[0].$2, isNull);
      final (_, body, contentType) = api.posts[2];
      expect(contentType, 'application/json');
      // Same body as the Apidog example.
      expect(body, {
        'salary_amount': 25000,
        'currency_id': 1,
        'work_type': 'full_time',
        'work_mode': 'hybrid',
        'work_start_day': 'sunday',
        'work_end_day': 'thursday',
        'hybrid_work_days': ['thursday'],
        'work_hours': 8,
        'notice_period_days': 30,
        'work_location': 'Cairo, Egypt',
      });
      expect(
        ApiOffersRepository.counterBody(
          const CounterOffer(
            salary: 1,
            workMode: 'remote',
            hybridDays: [DateTime.monday],
            noticeDays: 0,
            location: 'x',
          ),
        ).containsKey('hybrid_work_days'),
        isFalse,
      );

      api.reply = {'success': false, 'message': 'This offer has expired.'};
      final rejected = await repository.accept('9');
      expect(rejected.getErrorOrThrow().message, 'This offer has expired.');
      api.reply = 'oops';
      final invalid = await repository.reject('9');
      expect(invalid.getErrorOrThrow().message, 'offers_action_failed');
    },
  );

  test('actions follow available_actions only, not the status', () {
    HiringOfferDetails details(String status, List<String> actions) =>
        HiringOfferDetails.fromJson(_offer(status: status, actions: actions))!;
    for (final action in _answer) {
      // An "offer" whose newest version is the talent's or expired.
      expect(details('offer', const ['view']).allows(action), isFalse);
      expect(
        details('offer', const ['view', ..._answer]).allows(action),
        isTrue,
      );
    }
    // The old short names are not actions.
    expect(details('offer', const ['accept']).allows('accept_offer'), isFalse);
  });

  test('cubit runs an action, then reloads the offer', () async {
    final repo = _Repo(const ['view', 'accept_offer']);
    final cubit = OfferDetailsCubit(repo, '9');
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.details!.allows('accept_offer'), isTrue);
    expect(await cubit.accept(), isNull);
    expect(repo.calls, ['accept 9']);
    expect(repo.loads, 2);
    expect(cubit.state.details!.allows('accept_offer'), isFalse);

    repo.failure = const ServerFailure(message: 'This offer has expired.');
    expect((await cubit.reject())?.message, 'This offer has expired.');
    expect(repo.loads, 3);
    expect(cubit.state.submitting, isFalse);
  });

  testWidgets('buttons follow available_actions; accept asks first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    Future<void> pump(_Repo repo) async {
      await tester.pumpWidget(
        EasyLocalization(
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
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    // Still an "offer" but only "view" (own counter pending, or
    // expired): no buttons.
    await pump(_Repo(const ['view']));
    expect(find.text('Accept Offer'), findsNothing);
    expect(find.text('Reject'), findsNothing);
    expect(find.text('Negotiate'), findsNothing);

    // Accept: confirm, send, reload (the buttons go away).
    final repo = _Repo(const ['view', ..._answer]);
    await pump(repo);
    expect(find.text('Accept Offer'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Negotiate'), findsOneWidget);
    await tap(find.text('Accept Offer'));
    expect(find.text('Accept this offer?'), findsOneWidget);
    await tap(find.text('Cancel'));
    expect(repo.calls, isEmpty);
    await tap(find.text('Accept Offer'));
    await tap(find.widgetWithText(TextButton, 'Accept Offer'));
    expect(repo.calls, ['accept 9']);
    expect(find.text('Offer accepted'), findsOneWidget);
    expect(find.text('Accept Offer'), findsNothing);

    // Counter: prefilled from the client offer; office days are required.
    repo
      ..status = 'offer'
      ..actions = const ['view', ..._answer];
    await pump(repo);
    await tap(find.text('Negotiate'));
    expect(find.text('Submit Counter Offer'), findsOneWidget);
    expect(find.text('Cairo, Egypt'), findsOneWidget);
    // Office days sit beside the work mode, prefilled from the offer.
    expect(find.text('Thu'), findsOneWidget);
    Future<void> toggle(List<String> days) async {
      await tap(find.byKey(const ValueKey('counter-hybrid-days')));
      for (final day in days) {
        await tap(find.widgetWithText(CheckboxListTile, day));
      }
      await tap(find.text('Done'));
    }

    await toggle(['Thursday']);
    expect(find.text('Thu'), findsNothing);
    await tap(find.text('Send Counter Offer'));
    expect(find.text('Choose at least one office day'), findsOneWidget);
    await toggle(['Sunday']);
    expect(find.text('Sun'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('counter-salary')),
      '25000',
    );
    await tap(find.text('Send Counter Offer'));
    expect(repo.calls.last, 'counter 9');
    final sent = repo.countered!;
    expect(sent.salary, 25000);
    expect(sent.currencyId, 1);
    expect(sent.workMode, 'hybrid');
    expect(sent.hybridDays, [DateTime.sunday]);
    expect(sent.noticeDays, 30);
    expect(sent.location, 'Cairo, Egypt');
    expect(find.text('Counter offer sent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
