import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/app/app.dart';
import 'package:qader/app/di/dependencies.dart';
import 'package:qader/core/env/app_env.dart';
import 'package:qader/core/locale/language_manager.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/auth/domain/entities/account_role.dart';
import 'package:qader/features/auth/domain/entities/email_verification_challenge.dart';
import 'package:qader/features/auth/presentation/view/sign_up_view.dart';

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

/// Answers every auth POST with a success (recovery hands out a reset token).
class _Api extends Fake implements ApiConsumer {
  final paths = <String>[];
  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic) fromJson,
  }) async {
    paths.add(path);
    return Right(
      fromJson({
        'success': true,
        'data': {'reset_password_token': 'reset'},
      }),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('client recovery and email verification follow the client Figma '
      'frames', (tester) async {
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
    addTearDown(sl.reset);
    final api = _Api();
    await sl.unregister<ApiConsumer>();
    sl.registerSingleton<ApiConsumer>(api);
    for (final family in ['Poppins', 'Rubik']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
    final captureKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: EasyLocalization(
          supportedLocales: const [englishLocale, arabicLocale],
          path: assetPathLanguage,
          startLocale: englishLocale,
          saveLocale: false,
          assetLoader: const _Translations(),
          child: const MyApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/design_review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    Future<void> tap(String text) async {
      await tester.tap(find.widgetWithText(ElevatedButton, text));
      await tester.pumpAndSettle();
    }

    // Only the client sign-in offers "Sign up as company"; it opens the
    // client registration.
    AppRouter.router.go('${AppRouter.signIn}?role=talent');
    await tester.pumpAndSettle();
    expect(find.text('Sign up as company'), findsNothing);
    AppRouter.router.go('${AppRouter.signIn}?role=client');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign up as company'));
    await tester.tap(find.text('Sign up as company'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SignUpView>(find.byType(SignUpView)).role,
      AccountRole.client,
    );

    AppRouter.router.go('${AppRouter.forgotPassword}?role=client');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'client@qader.test');
    await tap('Reset Password');
    expect(api.paths.last, '/auth/client/password-reset/send-otp');
    expect(
      find.text(
        'Enter the verification code we just sent on your work email address.',
      ),
      findsOneWidget,
    );
    expect(find.text("Didn't receive the code?"), findsOneWidget);
    await capture('client_recovery_code');

    await tester.tap(find.widgetWithText(TextButton, 'Resend'));
    await tester.pumpAndSettle();
    expect(api.paths.last, '/auth/client/password-reset/send-otp');

    await tester.enterText(find.byType(EditableText), '123456');
    await tap('Done');
    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Your password must be :'), findsOneWidget);
    await capture('client_recovery_password');

    AppRouter.router.go(
      AppRouter.verifyEmail,
      extra: const EmailVerificationChallenge(
        email: 'company@example.com',
        role: AccountRole.client,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verify your email'), findsOneWidget);
    expect(
      find.textContaining('has been sent to company@example.com'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ElevatedButton, 'Verify Code'), findsOneWidget);
    await capture('client_verify_email');

    await tester.element(find.byType(MyApp)).setLocale(arabicLocale);
    await tester.pumpAndSettle();
    await capture('client_verify_email_arabic');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
