import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/home/domain/repositories/application_repository.dart';
import 'package:qader/features/home/domain/talent_application.dart';
import 'package:qader/features/home/presentation/view/application_status_view.dart';
import 'package:qader/features/home/presentation/view/home_view.dart';
import 'package:qader/features/home/presentation/view/widgets/application_review_banner.dart';

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

/// Returns queued results for `load()`, one per call.
class _Repo extends Fake implements ApplicationRepository {
  _Repo(this.results);
  final List<Either<Failure, TalentApplication>> results;
  int loads = 0;
  Completer<void>? gate;

  @override
  Future<Either<Failure, TalentApplication>> load() async {
    loads++;
    await gate?.future;
    return results.length > 1 ? results.removeAt(0) : results.single;
  }
}

Either<Failure, TalentApplication> _app(
  String screenState, {
  List<Map<String, dynamic>> faqs = const [],
}) => Right(
  TalentApplication.fromJson({
    'id': 1,
    'status': 'x',
    'status_label': 'Label',
    'screen_state': screenState,
    'faqs': faqs,
  }),
);

void main() {
  Future<void> pump(WidgetTester tester, _Repo repo) async {
    tester.view.physicalSize = const Size(390, 1600);
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
          builder: (context) => RepositoryProvider<ApplicationRepository>.value(
            value: repo,
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const HomeView(preview: false),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('under review shows the dashboard with the API FAQs', (
    tester,
  ) async {
    final repo = _Repo([
      _app(
        'under_review',
        faqs: [
          {
            'question': 'What does "Under Review" mean?',
            'answer': 'We are reviewing it.',
            'screen_states': ['under_review'],
            'display_order': 1,
          },
          {
            'question': 'Only for rejected',
            'answer': '-',
            'screen_states': ['rejected'],
            'display_order': 0,
          },
        ],
      ),
    ]);
    await pump(tester, repo);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ApplicationReviewBanner), findsOneWidget);
    expect(find.byType(ApplicationStatusView), findsNothing);
    expect(find.text('What does "Under Review" mean?'), findsOneWidget);
    expect(find.text('Only for rejected'), findsNothing);
  });

  testWidgets('other screen states open the matching status screen', (
    tester,
  ) async {
    await pump(tester, _Repo([_app('interview_confirmed')]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final view = tester.widget<ApplicationStatusView>(
      find.byType(ApplicationStatusView),
    );
    expect(view.initialStatus.name, 'confirmed');
    expect(view.application?.screenState, 'interview_confirmed');
  });

  testWidgets('shows loading, then an error with a working retry', (
    tester,
  ) async {
    final repo = _Repo([
      const Left(NetworkFailure(message: 'offline')),
      _app('under_review'),
    ])..gate = Completer<void>();
    await pump(tester, repo);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repo.gate!.complete();
    repo.gate = null;
    await tester.pumpAndSettle();
    expect(
      find.text("We couldn't load your application status."),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repo.loads, 2);
    expect(find.byType(ApplicationReviewBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no FAQ card when the backend sends none for the screen', (
    tester,
  ) async {
    await pump(tester, _Repo([_app('under_review')]));
    await tester.pumpAndSettle();
    expect(find.byType(ApplicationReviewBanner), findsOneWidget);
    expect(find.text('Review Process — FAQ'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pump(tester, _Repo([_app('accepted')]));
    await tester.pumpAndSettle();
    expect(find.byType(ApplicationStatusView), findsOneWidget);
    expect(find.text('Review Process — FAQ'), findsNothing);
    expect(find.text('Interview Req'), findsNothing);
  });
}
