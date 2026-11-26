import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/app/app.dart';
import 'package:qader/app/di/dependencies.dart';
import 'package:qader/core/env/app_env.dart';
import 'package:qader/core/locale/language_manager.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/auth/presentation/view/splash_view.dart';

class _Prefs extends Fake implements AppPreferences {
  _Prefs({this.loggedIn = false, this.onboarded = false, this.role = ''});
  final bool loggedIn, onboarded;
  final String role;
  @override
  bool get isLoggedIn => loggedIn;
  @override
  bool isOnBoardingViewed() => onboarded;
  @override
  String getAccountRole() => role;
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

/// Starts the real app signed out and returns where [location] ends up.
Future<String> _land(WidgetTester tester, String location) async {
  AppRouter.router.go(location);
  await tester.pumpAndSettle();
  return AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
}

void main() {
  test('the splash picks the first screen from the saved state', () {
    expect(splashDestination(_Prefs()), AppRouter.onboarding);
    expect(splashDestination(_Prefs(onboarded: true)), AppRouter.chooseRole);
    expect(
      splashDestination(_Prefs(loggedIn: true, onboarded: true)),
      AppRouter.profileSetup,
    );
    expect(
      splashDestination(
        _Prefs(loggedIn: true, onboarded: true, role: 'client'),
      ),
      AppRouter.account,
    );
  });

  testWidgets('signed-out redirects', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    AppEnv.init(Environment.dev, splashDuration: const Duration(seconds: 1));
    await EasyLocalization.ensureInitialized();
    await initServiceLocator(
      preferencesOverride: AppPreferencesImpl(
        await SharedPreferences.getInstance(),
      ),
    );
    addTearDown(sl.reset);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [englishLocale, arabicLocale],
        path: assetPathLanguage,
        startLocale: englishLocale,
        saveLocale: false,
        assetLoader: const _Translations(),
        child: const MyApp(),
      ),
    );
    // Splash, then the intro on a first visit.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
      AppRouter.onboarding,
    );

    // Account needs a session.
    expect(
      await _land(tester, AppRouter.account),
      '${AppRouter.signIn}?role=talent',
    );
    // Steps opened without their data (e.g. a restored deep link) go back
    // to where that data is made.
    expect(
      await _land(tester, AppRouter.verifyEmail),
      '${AppRouter.signIn}?role=talent',
    );
    // Signed out, only sample offers open; an unknown id goes to the list.
    expect(
      await _land(tester, '${AppRouter.offers}/no-such-offer'),
      AppRouter.offers,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
