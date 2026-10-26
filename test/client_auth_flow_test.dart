import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/app/app.dart';
import 'package:qader/app/env/app_env.dart';
import 'package:qader/core/di/service_locator.dart';
import 'package:qader/core/locale/language_manager.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/core/storage/secure_app_preferences.dart';
import 'package:qader/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'auth_repository_test.dart' show AuthApi, loginResponse;

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
    'client form authenticates, restores and logs out through real wiring',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      AppEnv.init(Environment.dev);
      await EasyLocalization.ensureInitialized();
      await initServiceLocator();
      final api = AuthApi()
        ..failure = const UnauthorizedFailure(message: 'Wrong credentials');
      await sl.unregister<ApiConsumer>();
      sl.registerSingleton<ApiConsumer>(api);
      final prefs = sl<AppPreferences>();
      expect(prefs, isA<SecureAppPreferences>());
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
      await tester.pumpAndSettle();
      AppRouter.router.go(AppRouter.account);
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routeInformationProvider.value.uri.path,
        AppRouter.signIn,
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'client@example.test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('Wrong credentials'), findsOneWidget);
      expect(prefs.isLoggedIn, isFalse);

      api.failure = null;
      api.response = loginResponse();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('My account'), findsOneWidget);
      expect(find.text('Test Client'), findsOneWidget);
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
      AppRouter.router.go(AppRouter.root);
      await tester.pumpAndSettle();
      expect(find.text('My account'), findsOneWidget);
      expect(find.text('client@example.test'), findsOneWidget);

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
