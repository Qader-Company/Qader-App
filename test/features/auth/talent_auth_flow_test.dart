import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/app/app.dart';
import 'package:qader/core/env/app_env.dart';
import 'package:qader/app/di/dependencies.dart';
import 'package:qader/core/locale/language_manager.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/core/storage/secure_app_preferences.dart';
import 'package:qader/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'auth_repository_test.dart' show AuthApi, loginResponse;
import '../../fixtures/onboarding_progress_fixture.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/features/profile_setup/presentation/widgets/professional_field_step.dart';

class _AuthWithProgress extends AuthApi {
  int progressReads = 0;
  Object progress = progressResponse(completed: true);
  Failure? progressFailure;
  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    if (path == '/talent/onboarding') {
      progressReads++;
      return progressFailure == null
          ? Right(fromJson(progress))
          : Left(progressFailure!);
    }
    if (path == '/talent/application') {
      return Right(
        fromJson({
          'success': true,
          'data': {
            'id': 1,
            'status': 'under_review',
            'screen_state': 'under_review',
            'faqs': <Object>[],
          },
        }),
      );
    }
    if (path.startsWith('/talent/master-data/')) {
      return Right(fromJson({'success': true, 'data': <Object>[]}));
    }
    return super.get(
      path,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );
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
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'talent form authenticates, restores and logs out through real wiring',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      AppEnv.init(Environment.dev);
      await EasyLocalization.ensureInitialized();
      await initServiceLocator();
      final api = _AuthWithProgress()
        ..failure = const UnauthorizedFailure(message: 'Wrong credentials');
      await sl.unregister<ApiConsumer>();
      sl.registerSingleton<ApiConsumer>(api);
      final prefs = sl<AppPreferences>();
      expect(prefs, isA<SecureAppPreferences>());
      Widget app() => EasyLocalization(
        supportedLocales: const [englishLocale, arabicLocale],
        path: assetPathLanguage,
        startLocale: englishLocale,
        saveLocale: false,
        assetLoader: const _Translations(),
        child: const MyApp(),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      AppRouter.router.go(AppRouter.account);
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routeInformationProvider.value.uri.path,
        AppRouter.signIn,
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'talent@example.test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      final passwordInput = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(passwordInput).autocorrect, isFalse);
      expect(
        tester.widget<TextField>(passwordInput).enableSuggestions,
        isFalse,
      );
      expect(
        tester.widget<TextField>(passwordInput).keyboardType,
        TextInputType.visiblePassword,
      );
      await tester.tap(find.byTooltip('show_password'.tr()));
      await tester.pump();
      expect(tester.widget<TextField>(passwordInput).obscureText, isFalse);
      expect(tester.widget<TextField>(passwordInput).autocorrect, isFalse);
      expect(
        tester.widget<TextField>(passwordInput).enableSuggestions,
        isFalse,
      );
      // Visibility and keyboard configuration must never rewrite a password.
      await tester.enterText(
        find.byType(TextFormField).at(1),
        ' MixedCase42! ',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(api.body?['password'], ' MixedCase42! ');
      expect(api.body?['email'], 'talent@example.test');
      expect(find.text('Wrong credentials'), findsOneWidget);
      expect(prefs.isLoggedIn, isFalse);

      api.failure = null;
      api.response = loginResponse();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routeInformationProvider.value.uri.path,
        AppRouter.home,
      );
      expect(find.text('My account'), findsNothing);
      expect(find.text('auth_complete_profile'.tr()), findsNothing);
      expect(find.text('Olivia Rhye'), findsNothing);
      expect(
        find.textContaining('Test Talent', findRichText: true),
        findsOneWidget,
      );
      expect(prefs.isLoggedIn, isTrue);
      expect(sl<SharedPreferences>().getString('PREFS_KEY_TOKEN'), isNull);

      // A fresh cubit and fresh secure-storage cache simulate restarting the app.
      AppRouter.router.go(AppRouter.chooseRole);
      await tester.pumpAndSettle();
      await sl.unregister<AuthSessionCubit>();
      final restoredPrefs = await SecureAppPreferences.create(
        sl<SharedPreferences>(),
      );
      expect(restoredPrefs.getToken(), 'access');
      sl.registerLazySingleton<AuthSessionCubit>(
        () => AuthSessionCubit(sl(), prefs),
        dispose: (cubit) => cubit.close(),
      );
      // A restart builds a new widget tree, so providers pick up the new
      // registrations.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      AppRouter.router.go(AppRouter.root);
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routeInformationProvider.value.uri.path,
        AppRouter.home,
      );
      expect(find.text('auth_complete_profile'.tr()), findsNothing);
      expect(
        find.textContaining('Test Talent', findRichText: true),
        findsOneWidget,
      );
      expect(api.progressReads, 2);

      // Reopening an unfinished account resumes the server's step, not Account.
      api.progress = progressResponse();
      api.progressFailure = const NetworkFailure(message: 'offline');
      AppRouter.router.go(AppRouter.root);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not load your saved progress. Please retry to continue.',
        ),
        findsOneWidget,
      );
      api.progressFailure = null;
      await tester.tap(find.widgetWithText(TextButton, 'auth_retry'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('Skills & Experience'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Backend engineer'),
        findsOneWidget,
      );
      expect(api.progressReads, 4);

      // A first-time account goes straight from login to Professional Field.
      await prefs.logout();
      await tester.pumpAndSettle();
      api.progress = newAccountProgressResponse();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'talent@example.test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routeInformationProvider.value.uri.path,
        AppRouter.profileSetup,
      );
      expect(find.byType(ProfessionalFieldStep), findsOneWidget);
      expect(find.text('auth_complete_profile'.tr()), findsNothing);
      // Restarting this same new account must not skip field selection either.
      AppRouter.router.go(AppRouter.root);
      await tester.pumpAndSettle();
      expect(find.byType(ProfessionalFieldStep), findsOneWidget);
      expect(
        AppRouter.router.routeInformationProvider.value.uri.path,
        AppRouter.profileSetup,
      );
      AppRouter.router.go(AppRouter.account);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(prefs.isLoggedIn, isFalse);
      expect(
        AppRouter.router.routeInformationProvider.value.uri.path,
        AppRouter.signIn,
      );
      final afterLogout = await SecureAppPreferences.create(
        sl<SharedPreferences>(),
      );
      expect(afterLogout.getToken(), isEmpty);
      expect(afterLogout.getRefreshToken(), isEmpty);
      AppRouter.router.go(AppRouter.account);
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routeInformationProvider.value.uri.path,
        AppRouter.signIn,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await sl.reset();
    },
  );
}
