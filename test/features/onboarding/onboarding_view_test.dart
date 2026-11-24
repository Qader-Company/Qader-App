import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/onboarding/presentation/view/onboarding_view.dart';

class _Prefs extends Fake implements AppPreferences {
  /// Completes the next save; a fresh one is made after each call.
  Completer<void> save = Completer();
  int saves = 0;
  @override
  Future<void> setOnBoardingViewed() {
    saves++;
    return save.future;
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

Future<void> _pump(WidgetTester tester, _Prefs prefs) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  final router = GoRouter(
    initialLocation: AppRouter.onboarding,
    routes: [
      GoRoute(
        path: AppRouter.onboarding,
        builder: (_, _) => const OnboardingView(),
      ),
      GoRoute(
        path: AppRouter.chooseRole,
        builder: (_, _) => const Scaffold(body: Text('choose role')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
      startLocale: const Locale('en', 'US'),
      saveLocale: false,
      path: 'assets/translations',
      assetLoader: const _Translations(),
      child: Builder(
        builder: (context) => RepositoryProvider<AppPreferences>.value(
          value: prefs,
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp.router(
              routerConfig: router,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _progress(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
    .value!;

Future<void> _toLastPage(WidgetTester tester) async {
  for (var i = 0; i < 2; i++) {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('swiping moves the progress bar both ways', (tester) async {
    await _pump(tester, _Prefs());
    final first = _progress(tester);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(_progress(tester), greaterThan(first));
    expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(_progress(tester), first);
  });

  testWidgets('Get Started saves once, then opens choose role', (tester) async {
    final prefs = _Prefs();
    await _pump(tester, prefs);
    await _toLastPage(tester);
    expect(_progress(tester), 1);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pump();
    // While saving the button is busy, so a second tap does nothing.
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pump();
    expect(prefs.saves, 1);
    prefs.save.complete();
    await tester.pumpAndSettle();
    expect(find.text('choose role'), findsOneWidget);
    expect(find.byType(OnboardingView), findsNothing);
  });

  testWidgets('a failed save stays on the page and can be retried', (
    tester,
  ) async {
    final prefs = _Prefs();
    await _pump(tester, prefs);
    await _toLastPage(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pump();
    prefs.save.completeError(Exception('disk full'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingView), findsOneWidget);
    expect(
      find.text('Could not save your progress. Please try again.'),
      findsOneWidget,
    );

    // The toast floats over the bottom button; close it before retrying.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    prefs.save = Completer()..complete();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pumpAndSettle();
    expect(prefs.saves, 2);
    expect(find.text('choose role'), findsOneWidget);
  });
}
