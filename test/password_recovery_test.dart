import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/app/app.dart';
import 'package:qader/app/env/app_env.dart';
import 'package:qader/core/di/service_locator.dart';
import 'package:qader/core/locale/language_manager.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/auth/data/datasources/talent_auth_remote_data_source.dart';
import 'package:qader/features/auth/data/repositories/password_recovery_repository.dart';
import 'package:qader/features/auth/presentation/cubit/password_recovery_cubit.dart';
import 'package:qader/features/auth/presentation/view/sign_in_view.dart';
import 'auth_repository_test.dart' show AuthApi;

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
  late AppPreferences prefs;
  late AuthApi api;
  late PasswordRecoveryRepository repository;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = AppPreferencesImpl(await SharedPreferences.getInstance());
    api = AuthApi()..response = {'success': true};
    repository = PasswordRecoveryRepository(
      TalentAuthRemoteDataSource(api),
      prefs,
    );
  });

  test(
    'recovery sends email, verifies six digits and resets with its own Bearer',
    () async {
      await prefs.saveVerificationToken('email-verification');
      final request = (await repository.begin(
        ' talent@example.test ',
      )).getOrThrow();
      expect(api.path, '/auth/talent/password-reset/send-otp');
      expect(api.body, {'email': 'talent@example.test'});
      expect(api.credential, '');
      expect(
        (await repository.reset(request, 'password123', 'password123')).isError,
        isTrue,
      );
      expect((await repository.verify(request, '12345')).isError, isTrue);
      expect(api.calls, 1);
      api.response = {
        'success': true,
        'data': {
          'reset_password_token': {'token': 'reset-only', 'ttl': 60},
        },
      };
      expect((await repository.verify(request, '123456')).isSuccess, isTrue);
      expect(api.path, '/auth/talent/reset-password-verification');
      expect(api.body, {'email': 'talent@example.test', 'otp': '123456'});
      expect(api.credential, '');
      expect(prefs.getResetPasswordToken(), 'reset-only');
      expect(prefs.getVerificationToken(), 'email-verification');
      api.response = {'success': true};
      expect(
        (await repository.reset(request, 'password123', 'different')).isError,
        isTrue,
      );
      api.failure = const ServerFailure(message: 'Try again');
      expect(
        (await repository.reset(request, 'password123', 'password123')).isError,
        isTrue,
      );
      expect(prefs.getResetPasswordToken(), 'reset-only');
      api.failure = null;
      expect(
        (await repository.reset(
          request,
          'password123',
          'password123',
        )).isSuccess,
        isTrue,
      );
      expect(api.path, '/auth/talent/reset-password');
      expect(api.body, {
        'password': 'password123',
        'password_confirmation': 'password123',
      });
      expect(api.credential, 'reset-only');
      expect(prefs.getResetPasswordToken(), isEmpty);
      expect(prefs.isLoggedIn, isFalse);
      expect(prefs.getRefreshToken(), isEmpty);
      expect(
        (await repository.reset(request, 'password123', 'password123')).isError,
        isTrue,
      );
    },
  );

  test(
    'malformed verification never unlocks reset; resend errors allow retry',
    () async {
      final request = (await repository.begin(
        'talent@example.test',
      )).getOrThrow();
      for (final response in [
        null,
        {'success': false},
        {'success': true},
        {
          'success': true,
          'data': {'reset_password_token': ''},
        },
      ]) {
        api.response = response;
        expect((await repository.verify(request, '123456')).isError, isTrue);
        expect(prefs.getResetPasswordToken(), isEmpty);
      }
      api.failure = const NetworkFailure(message: 'offline');
      expect((await repository.resend(request)).isError, isTrue);
      api.failure = null;
      api.response = {'success': true};
      expect((await repository.resend(request)).isSuccess, isTrue);
      expect(api.path, '/auth/talent/password-reset/send-otp');
      api.response = {
        'success': true,
        'data': {'reset_password_token': 'string-reset-token'},
      };
      expect((await repository.verify(request, '123456')).isSuccess, isTrue);
      expect(prefs.getResetPasswordToken(), 'string-reset-token');
      api.response = {'success': false};
      expect(
        (await repository.reset(request, 'password123', 'password123')).isError,
        isTrue,
      );
      expect(prefs.getResetPasswordToken(), 'string-reset-token');
    },
  );

  test(
    'new request rejects old challenges; logout rejects late verification',
    () async {
      final old = (await repository.begin('old@example.test')).getOrThrow();
      final current = (await repository.begin('new@example.test')).getOrThrow();
      expect((await repository.verify(old, '123456')).isError, isTrue);
      api.gate = Completer<void>();
      api.response = {
        'success': true,
        'data': {'reset_password_token': 'late'},
      };
      final pending = repository.verify(current, '123456');
      await prefs.logout();
      api.gate!.complete();
      expect((await pending).isError, isTrue);
      expect(prefs.getResetPasswordToken(), isEmpty);
    },
  );

  test(
    'Cubit prevents duplicate send and overlapping resend and verification',
    () async {
      final cubit = PasswordRecoveryCubit(repository);
      api.gate = Completer<void>();
      final send = cubit.send('talent@example.test');
      await cubit.send('other@example.test');
      api.gate!.complete();
      await send;
      expect(api.calls, 1);
      expect(cubit.state.step, PasswordRecoveryStep.code);
      api.gate = Completer<void>();
      final resend = cubit.resend();
      await cubit.verify('123456');
      await cubit.resend();
      expect(api.calls, 2);
      api.gate!.complete();
      await resend;
      expect(cubit.state.resent, isTrue);
      api.failure = const ServerFailure(message: 'Invalid OTP');
      await cubit.verify('123456');
      expect(cubit.state.step, PasswordRecoveryStep.code);
      expect(cubit.state.failure?.message, 'Invalid OTP');
      await cubit.close();
    },
  );

  testWidgets('Talent recovery validates inputs and completes all API stages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    AppEnv.init(Environment.dev);
    await EasyLocalization.ensureInitialized();
    await initServiceLocator(preferencesOverride: prefs);
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
    AppRouter.router.go('/forgot-password?role=talent');
    await tester.pumpAndSettle();
    Future<void> tap(String text) async {
      final button = find.widgetWithText(ElevatedButton, text);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await tap('Send reset code');
    expect(api.calls, 0);
    await tester.enterText(find.byType(TextFormField), ' talent@example.test ');
    await tap('Send reset code');
    expect(tester.widget<Pinput>(find.byType(Pinput)).length, 6);
    await tester.enterText(find.byType(EditableText), '12345');
    await tap('Done');
    expect(find.text('Enter a 6-digit code.'), findsOneWidget);
    api.response = {
      'success': true,
      'data': {'reset_password_token': 'reset-only'},
    };
    await tester.enterText(find.byType(EditableText), '123456');
    await tap('Done');
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).at(0), 'short');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tap('Reset Password');
    expect(api.calls, 2);
    await tester.enterText(find.byType(TextFormField).at(0), 'password123');
    await tester.enterText(find.byType(TextFormField).at(1), 'mismatch');
    await tap('Reset Password');
    expect(api.calls, 2);
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    api.failure = const ServerFailure(message: 'Please retry');
    await tap('Reset Password');
    expect(find.text('Please retry'), findsOneWidget);
    api.failure = null;
    api.response = {'success': true};
    await tap('Reset Password');
    expect(find.text('Password updated'), findsOneWidget);
    expect(prefs.getResetPasswordToken(), isEmpty);
    expect(prefs.isLoggedIn, isFalse);
    await tap('Sign In');
    expect(find.byType(SignInView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.element(find.byType(SignInView)).setLocale(arabicLocale);
    tester.view.physicalSize = const Size(320, 640);
    AppRouter.router.go('/forgot-password?role=talent');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'arabic@example.test');
    await tap('auth_send_reset_code'.tr());
    await tester.enterText(
      find.byType(EditableText),
      '\u0661\u0662\u0663\u0664\u0665\u0666',
    );
    expect(
      tester.widget<Pinput>(find.byType(Pinput)).controller!.text,
      '123456',
    );
    api.response = {
      'success': true,
      'data': {'reset_password_token': 'arabic-reset'},
    };
    await tap('otp_done'.tr());
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await sl.reset();
  });
}
