import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/resources/theme_manager.dart';
import 'package:qader/features/offers/data/repositories/api_offers_repository.dart';
import 'package:qader/features/offers/domain/entities/hiring_offer_details.dart';
import 'package:qader/features/offers/domain/repositories/offers_repository.dart';
import 'package:qader/features/offers/presentation/view/live_offer_details_view.dart';

/// `interview` of the Apidog "Get Hiring Interview" examples: the talent's
/// [response] and the [actions] it allows.
Map<String, dynamic> _interview({
  String status = 'awaiting_responses',
  String statusLabel = 'Awaiting Responses',
  String response = 'pending',
  String responseLabel = 'Pending',
  String? meetingUrl,
  bool canJoin = false,
  List<String> actions = const [
    'accept_schedule',
    'request_schedule_change',
    'apologize',
  ],
}) => {
  'id': 5,
  'status': status,
  'status_label': statusLabel,
  'start': '2026-11-22T10:00:00.000000Z',
  'end': '2026-11-22T11:00:00.000000Z',
  'duration_minutes': 60,
  'talent_response': {
    'status': response,
    'status_label': responseLabel,
    'reason': null,
    'responded_at': null,
  },
  'meeting_url': meetingUrl,
  'can_join': canJoin,
  'available_actions': actions,
};

/// "Interview stage" of Get Hiring Offer with [interview].
HiringOfferDetails _item(Map<String, dynamic> interview) =>
    HiringOfferDetails.fromJson({
      'id': 7,
      'status': 'interview',
      'status_label': 'Interview',
      'interview_required': true,
      'company': {'id': 1, 'name': 'Qader Technology', 'logo_url': null},
      'offer': {
        'id': 10,
        'proposed_by': 'client',
        'salary_amount': '25000.0000',
        'currency': {'id': 1, 'code': 'EGP'},
        'status': 'accepted',
        'status_label': 'Accepted',
      },
      'interview': interview,
      'available_actions': ['view'],
    })!;

class _Api extends Fake implements ApiConsumer {
  Object? reply = {
    'success': true,
    'message': 'ok',
    'data': <String, dynamic>{},
  };
  final posts = <(String, Object?)>[];
  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic json) fromJson,
  }) async {
    posts.add((path, data));
    return Right(fromJson(reply));
  }
}

/// Moves the interview the way the server does after each answer.
class _Repo extends Fake implements OffersRepository {
  var interview = _interview();
  final calls = <String>[];

  @override
  Future<Either<Failure, HiringOfferDetails>> loadOffer(String id) async =>
      Right(_item(interview));

  @override
  Future<Either<Failure, void>> acceptInterviewTime(String interviewId) async {
    calls.add('accept $interviewId');
    // "Talent accepted — waiting for client response".
    interview = _interview(
      response: 'accepted',
      responseLabel: 'Accepted',
      actions: const [],
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> requestInterviewChange(
    String interviewId,
    String reason,
  ) async {
    calls.add('change $interviewId: $reason');
    // "Awaiting reschedule".
    interview = _interview(
      status: 'awaiting_reschedule',
      statusLabel: 'Awaiting Reschedule',
      response: 'change_requested',
      responseLabel: 'Change Requested',
      actions: const [],
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> apologizeForInterview(
    String interviewId,
    String reason,
  ) async {
    calls.add('apologize $interviewId: $reason');
    return const Right(null);
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

void main() {
  test('interview answers post to the Apidog paths', () async {
    final api = _Api();
    final repository = ApiOffersRepository(api);
    expect((await repository.acceptInterviewTime('5')).isSuccess, isTrue);
    await repository.requestInterviewChange('5', 'Not a good time.');
    await repository.apologizeForInterview('5', 'Something came up.');
    expect(api.posts.map((post) => post.$1), [
      '/talent/hiring-interviews/5/accept-schedule',
      '/talent/hiring-interviews/5/request-schedule-change',
      '/talent/hiring-interviews/5/apologize',
    ]);
    expect(api.posts[0].$2, isNull);
    expect(api.posts[1].$2, {'reason': 'Not a good time.'});
    expect(api.posts[2].$2, {'reason': 'Something came up.'});
    api.reply = {'success': false, 'message': 'The interview time changed.'};
    expect(
      (await repository.acceptInterviewTime('5')).getErrorOrThrow().message,
      'The interview time changed.',
    );
  });

  testWidgets('buttons follow interview.available_actions; answers reload', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
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
              builder: (context, _) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: ThemeManager.getTheme(context.locale),
                home: Scaffold(
                  body: LiveOfferDetailsView(key: UniqueKey(), offerId: '7'),
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

    // Awaiting the talent's response: all three answers.
    final repo = _Repo();
    await pump(repo);
    expect(find.text('Accept Time'), findsOneWidget);
    expect(find.text('Request a New Time'), findsOneWidget);
    expect(find.text('Apologize'), findsOneWidget);

    // Accept: sent for interview 5, then the reloaded interview has no
    // answers left and shows the talent's response.
    await tap(find.text('Accept Time'));
    expect(repo.calls, ['accept 5']);
    expect(find.text('Interview time accepted'), findsOneWidget);
    expect(find.text('Accept Time'), findsNothing);
    expect(find.text('Accepted'), findsWidgets);

    // Request a new time: a reason is required (10+ characters).
    final changing = _Repo();
    await pump(changing);
    await tap(find.byKey(const ValueKey('interview-change')));
    expect(find.text('Send Request'), findsOneWidget);
    await tap(find.text('Send Request'));
    expect(find.text('Please write at least 10 characters'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('apologize-reason')),
      'The proposed time is not suitable.',
    );
    await tap(find.text('Send Request'));
    expect(changing.calls, ['change 5: The proposed time is not suitable.']);
    expect(find.text('Awaiting Reschedule'), findsOneWidget);
    expect(find.text('Change Requested'), findsOneWidget);
    expect(find.text('Request a New Time'), findsNothing);

    // Apologize: the same reason form, sent to the apologize endpoint.
    final sorry = _Repo();
    await pump(sorry);
    await tap(find.byKey(const ValueKey('interview-apologize')));
    expect(find.text('Apologize & Reschedule'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('apologize-reason')),
      'Something urgent came up.',
    );
    await tap(find.text('Submit Apology & Reschedule'));
    expect(sorry.calls, ['apologize 5: Something urgent came up.']);
    expect(find.text('Your apology was sent'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // "Interview in progress": the link and Join open the meeting outside
    // the app (its own app when installed).
    final opened = <String>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'launch') {
        opened.add((call.arguments as Map)['url'] as String);
        return true;
      }
      return call.method == 'canLaunch';
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final live = _Repo()
      ..interview = _interview(
        status: 'in_progress',
        statusLabel: 'In Progress',
        response: 'accepted',
        responseLabel: 'Accepted',
        meetingUrl: 'https://meet.google.com/abc-defg-hij',
        canJoin: true,
        actions: const [],
      );
    await pump(live);
    await tap(find.byKey(const ValueKey('interview-meeting-link')));
    await tap(find.text('Join Interview'));
    expect(opened, [
      'https://meet.google.com/abc-defg-hij',
      'https://meet.google.com/abc-defg-hij',
    ]);
    expect(find.text('Accept Time'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
