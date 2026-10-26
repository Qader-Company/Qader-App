import 'dart:convert';
import 'package:pinput/pinput.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
import 'package:qader/features/auth/presentation/view/sign_in_view.dart';
import 'auth_repository_test.dart' show AuthApi, registrationResponse;

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
    'Talent register validates, sends fields, handles errors and acknowledges success',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      AppEnv.init(Environment.dev);
      await EasyLocalization.ensureInitialized();
      await initServiceLocator(
        preferencesOverride: AppPreferencesImpl(
          await SharedPreferences.getInstance(),
        ),
      );
      final api = AuthApi()
        ..failure = const ValidationFailure(
          message: 'Email already taken',
          errors: ['Email already taken'],
        );
      await sl.unregister<ApiConsumer>();
      sl.registerSingleton<ApiConsumer>(api);
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
      AppRouter.router.go('${AppRouter.signUp}?role=talent');
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(5));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '  Demo ');
      await tester.enterText(fields.at(1), ' Talent  ');
      await tester.enterText(fields.at(2), ' talent@example.test ');
      await tester.enterText(fields.at(3), 'short!');
      await tester.enterText(fields.at(4), 'short!');
      Future<void> submit() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final button = find.widgetWithText(ElevatedButton, 'Sign up');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      await submit();
      expect(api.calls, 0);
      await tester.enterText(fields.at(3), 'password123');
      await tester.enterText(fields.at(4), 'password123');
      await submit();
      expect(api.path, '/auth/talent/register');
      expect(api.body, {
        'first_name': 'Demo',
        'last_name': 'Talent',
        'email': 'talent@example.test',
        'password': 'password123',
        'password_confirmation': 'password123',
      });
      expect(find.text('Email already taken'), findsOneWidget);
      expect(sl<AppPreferences>().isLoggedIn, isFalse);

      api.failure = null;
      api.response = registrationResponse();
      await submit();
      expect(find.byType(Pinput), findsOneWidget);
      expect(tester.widget<Pinput>(find.byType(Pinput)).length, 6);
      expect(sl<AppPreferences>().getVerificationToken(), 'verification-only');
      expect(sl<AppPreferences>().isLoggedIn, isFalse);
      expect(sl<AppPreferences>().getRefreshToken(), isEmpty);
      await tester.enterText(find.byType(EditableText), '12345');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Done'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a 6-digit code.'), findsOneWidget);
      api.failure = const ServerFailure(message: 'Invalid OTP');
      await tester.enterText(find.byType(EditableText), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Done'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid OTP'), findsOneWidget);
      expect(api.credential, 'verification-only');
      api.failure = null;
      api.response = {'success': true};
      await tester.tap(find.widgetWithText(ElevatedButton, 'Done'));
      await tester.pumpAndSettle();
      expect(find.text('Email verified. Sign in to continue.'), findsOneWidget);
      expect(sl<AppPreferences>().isLoggedIn, isFalse);
      expect(sl<AppPreferences>().getVerificationToken(), isEmpty);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SignInView>(find.byType(SignInView)).role.name,
        'talent',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await sl.reset();
    },
  );
}
