import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/talent_profile/data/repositories/api_talent_evaluation_repository.dart';
import 'package:qader/features/talent_profile/domain/entities/talent_evaluation.dart';
import 'package:qader/features/talent_profile/domain/repositories/talent_evaluation_repository.dart';
import 'package:qader/features/talent_profile/presentation/view/profile_evaluation_view.dart';
import 'package:qader/features/talent_profile/presentation/view/profile_review_view.dart';
import 'package:qader/features/talent_profile/presentation/widgets/evaluation_report_widgets.dart';
import 'package:qader/features/talent_profile/presentation/widgets/evaluation_skeleton.dart';

/// The 200 example of `GET /talent/profile/evaluation` in Apidog.
Map<String, dynamic> _example() => {
  'success': true,
  'data': {
    'application_id': 1,
    'profile_review': {
      'id': 7,
      'ratings': {
        'technical_skills': 4,
        'communication_skills': 4,
        'problem_solving': 5,
        'soft_skills': 4,
      },
      'average_rating': 4.25,
      'recommended_salary': {
        'min': '2500.0000',
        'max': '3200.0000',
        'currency': {
          'id': 1,
          'code': 'USD',
          'name': 'US Dollar',
          'symbol': r'$',
          'is_active': true,
        },
      },
      'reports': {
        'hr': 'Clear communicator.',
        'technical': 'Strong technical fundamentals.',
        'psychology': 'Calm under pressure.',
      },
      'tips': [
        {
          'id': 1,
          'title': 'Add measurable outcomes',
          'priority': 'high',
          'description': 'Quantify the impact of recent projects.',
          'display_order': 1,
        },
      ],
    },
    'interview_reviews': [
      {
        'interview_id': 11,
        'round_number': 1,
        'type': 'technical',
        'completed_at': '2026-11-05T12:00:00.000000Z',
        'evaluation': {
          'id': 4,
          'ratings': {
            'technical_skills': 4,
            'communication_skills': 5,
            'problem_solving': 4,
            'soft_skills': 5,
          },
          'average_rating': 4.5,
          'overall_score': 90,
          'reports': {
            'hr': 'Professional and prepared.',
            'technical': 'Solid system design answers.',
            'psychology': 'Confident and collaborative.',
          },
          'final_feedback': 'Recommended for the talent pool.',
        },
      },
    ],
  },
};

class _Api extends Fake implements ApiConsumer {
  _Api(this.result);
  final Either<Failure, Object?> result;
  String? path;
  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    this.path = path;
    return result.fold(Left.new, (raw) => Right(fromJson(raw)));
  }
}

class _Repo extends Fake implements TalentEvaluationRepository {
  _Repo(this.results);
  final List<Either<Failure, TalentEvaluation?>> results;
  Completer<void>? gate;
  int loads = 0;
  @override
  Future<Either<Failure, TalentEvaluation?>> load() async {
    await gate?.future;
    final index = loads.clamp(0, results.length - 1);
    loads++;
    return results[index];
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

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  tester.view.physicalSize = const Size(390, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
      startLocale: const Locale('en', 'US'),
      saveLocale: false,
      path: 'assets/translations',
      assetLoader: const _Translations(),
      child: Builder(
        builder: (context) =>
            RepositoryProvider<TalentEvaluationRepository>.value(
              value: repo,
              child: MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const ProfileEvaluationView(),
              ),
            ),
      ),
    ),
  );
}

void main() {
  test('parses the Apidog example', () {
    final evaluation = TalentEvaluation.fromJson(
      _example()['data'] as Map<String, dynamic>,
    );
    final profile = evaluation.profileReview!;
    expect(profile.ratings.keys, [
      'technical_skills',
      'communication_skills',
      'problem_solving',
      'soft_skills',
    ]);
    expect(profile.ratings['problem_solving'], 5);
    expect(profile.averageRating, 4.25);
    expect(profile.salary!.min, 2500);
    expect(profile.salary!.max, 3200);
    expect(profile.salary!.currency, 'USD');
    expect(profile.reports['psychology'], 'Calm under pressure.');
    expect(profile.tips.single.priority, 'high');
    final interview = evaluation.interviews.single;
    expect(interview.round, 1);
    expect(interview.type, 'technical');
    expect(interview.completedAt, DateTime.utc(2026, 11, 5, 12).toLocal());
    expect(interview.review.overallScore, 90);
    expect(interview.review.finalFeedback, 'Recommended for the talent pool.');
  });

  test('tolerates missing and odd fields', () {
    final evaluation = TalentEvaluation.fromJson({
      'profile_review': {
        'ratings': {'technical_skills': 'x', 'soft_skills': '3'},
        'reports': {'hr': '', 'technical': null},
        'recommended_salary': {'max': 900, 'currency': 'EGP'},
        'tips': [
          {'title': 'B', 'display_order': 2},
          {'title': 'A', 'display_order': '1'},
          'not a tip',
        ],
      },
      'interview_reviews': [
        {'round_number': 2},
        {
          'round_number': '2',
          'evaluation': {'overall_score': '70'},
        },
        {
          'round_number': 1,
          'evaluation': {'final_feedback': 'ok'},
        },
      ],
    });
    final profile = evaluation.profileReview!;
    expect(profile.ratings, {'soft_skills': 3});
    expect(profile.reports, isEmpty);
    expect(profile.salary!.min, isNull);
    expect(profile.salary!.currency, 'EGP');
    expect(profile.tips.map((tip) => tip.title), ['A', 'B']);
    // One without an evaluation is skipped; rounds are in order.
    expect(evaluation.interviews.map((i) => i.round), [1, 2]);
    expect(TalentEvaluation.fromJson(const {}).profileReview, isNull);
  });

  group('repository', () {
    test('loads the evaluation', () async {
      final api = _Api(Right(_example()));
      final result = await ApiTalentEvaluationRepository(api).load();
      expect(api.path, '/talent/profile/evaluation');
      expect(result.getOrThrow()!.interviews, hasLength(1));
    });

    test('404 means not available yet', () async {
      final result = await ApiTalentEvaluationRepository(
        _Api(
          const Left(
            ServerFailure(
              message: 'Your evaluation is not available yet.',
              statusCode: 404,
            ),
          ),
        ),
      ).load();
      expect(result.getOrThrow(), isNull);
    });

    test('a bad body or another failure is a failure', () async {
      final invalid = await ApiTalentEvaluationRepository(
        _Api(const Right({'success': true, 'data': []})),
      ).load();
      expect(invalid.getErrorOrThrow().message, 'talent_evaluation_failed');
      final offline = await ApiTalentEvaluationRepository(
        _Api(const Left(NetworkFailure(message: 'offline'))),
      ).load();
      expect(offline.getErrorOrThrow(), isA<NetworkFailure>());
    });
  });

  testWidgets('a signed-in talent sees the real evaluation', (tester) async {
    final evaluation = TalentEvaluation.fromJson(
      _example()['data'] as Map<String, dynamic>,
    );
    final repo = _Repo([Right(evaluation)])..gate = Completer();
    await _pump(tester, repo);
    await tester.pump();
    expect(find.byType(EvaluationSkeleton), findsOneWidget);
    repo.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('2,500–3,200 USD'), findsOneWidget);
    // The profile review starts open: its ratings, reports and tip.
    expect(find.byType(EvaluationMetricCard), findsNWidgets(4));
    expect(find.text('100%'), findsOneWidget); // problem solving 5/5
    expect(find.text('Strong technical fundamentals.'), findsOneWidget);
    expect(find.text('Add measurable outcomes'), findsOneWidget);
    expect(find.text('High Priority'), findsOneWidget);

    // The interview round, opened.
    await tester.tap(find.text('Technical Interview · Round 1'));
    await tester.pumpAndSettle();
    expect(find.text('Overall score: 90%'), findsOneWidget);
    expect(find.text('Recommended for the talent pool.'), findsOneWidget);
    expect(find.byType(EvaluationMetricCard), findsNWidgets(8));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'no evaluation yet offers the paid review; a failure can be retried',
    (tester) async {
      await _pump(tester, _Repo([const Right(null)]));
      await tester.pumpAndSettle();
      // No evaluation yet: the paid expert review is offered instead.
      expect(find.byType(ProfileReviewView), findsOneWidget);
      expect(find.text('Try again'), findsNothing);

      final repo = _Repo([
        const Left(NetworkFailure(message: 'offline')),
        Right(
          TalentEvaluation.fromJson(_example()['data'] as Map<String, dynamic>),
        ),
      ]);
      // A fresh screen, so a new cubit reads the new repository.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, repo);
      await tester.pumpAndSettle();
      expect(find.text("We couldn't load your evaluation"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(repo.loads, 2);
      expect(find.byType(EvaluationMetricCard), findsNWidgets(4));
    },
  );
}
