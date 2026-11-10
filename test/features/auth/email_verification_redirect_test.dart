import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/resources/qader_design.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/di/service_locator.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/features/auth/domain/entities/email_verification_challenge.dart';
import 'package:qader/features/auth/domain/repositories/auth_repository.dart';
import 'package:qader/features/auth/presentation/view/email_verification_view.dart';

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

class _Repo extends Fake implements AuthRepository {
  @override
  Future<Either<Failure, void>> verifyEmail(
    EmailVerificationChallenge challenge,
    String otp,
  ) async => const Right(null);
}

void main() {
  testWidgets('verified email goes straight to sign in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    sl.registerSingleton<AuthRepository>(_Repo());
    addTearDown(sl.reset);
    final router = GoRouter(
      initialLocation: AppRouter.verifyEmail,
      routes: [
        GoRoute(
          path: AppRouter.verifyEmail,
          builder: (_, _) => const EmailVerificationView(
            challenge: EmailVerificationChallenge(email: 'new@example.test'),
          ),
        ),
        GoRoute(
          path: AppRouter.signIn,
          builder: (_, state) => Scaffold(
            body: Text('sign-in ${state.uri.queryParameters['role']}'),
          ),
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
          builder: (context) => MaterialApp.router(
            theme: QaderDesign.apply(ThemeData(), context.locale),
            routerConfig: router,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(Pinput), '123456');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'otp_done'.tr()));
    await tester.pumpAndSettle();
    expect(find.text('sign-in talent'), findsOneWidget);
    expect(find.text('auth_email_verified'.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
