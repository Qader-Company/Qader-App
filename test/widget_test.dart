import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/app/app.dart';
import 'package:qader/app/env/app_env.dart';
import 'package:qader/core/di/service_locator.dart';
import 'package:qader/core/locale/language_manager.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/core/widgets/language_toggle_button.dart';
import 'package:qader/features/auth/presentation/view/sign_in_view.dart';
import 'package:qader/features/auth/presentation/view/sign_up_view.dart';
import 'package:pinput/pinput.dart';
import 'package:qader/features/auth/presentation/view/forgot_password_view.dart';
import 'package:qader/features/auth/presentation/view/otp_view.dart';
import 'package:qader/core/resources/assets_manager.dart';
import 'package:qader/features/onboarding/presentation/view/onboarding_view.dart';

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
  testWidgets('Figma flow, validation, preview, FAQ, and Arabic on a small screen', (
    tester,
  ) async {
    Future<void> settle() async {
      if (find.byType(Pinput).evaluate().isNotEmpty) {
        // Pinput's blinking cursor keeps scheduling frames while focused.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      } else {
        await tester.pumpAndSettle();
      }
    }

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    AppEnv.init(Environment.dev, splashDuration: const Duration(seconds: 1));
    await EasyLocalization.ensureInitialized();
    await initServiceLocator(
      preferencesOverride: AppPreferencesImpl(
        await SharedPreferences.getInstance(),
      ),
    );
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
    await settle();
    Future<void> capture(String name) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await settle();
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

    await tester.runAsync(() async {
      final context = tester.element(find.byType(MyApp));
      for (final asset in ImageAssets.onboardingImages) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await capture('01_splash');
    await tester.pump(const Duration(seconds: 1));
    await settle();

    expect(find.byType(OnboardingView), findsOneWidget);
    expect(find.text('Discover Opportunities That Fit You'), findsOneWidget);
    expect(sl<AppPreferences>().isOnBoardingViewed(), isFalse);
    await capture('16_intro_opportunities');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Next').hitTestable());
    await settle();
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .4906,
    );
    await capture('17_intro_team');
    // Swiping backwards and advancing again retains the correct page/progress.
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await settle();
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .1375,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Next').hitTestable());
    await settle();
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await settle();
    expect(find.text('Everything in One Place'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
    await capture('18_intro_dashboard');
    expect(sl<AppPreferences>().isOnBoardingViewed(), isFalse);
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Get Started').hitTestable(),
    );
    await settle();
    expect(sl<AppPreferences>().isOnBoardingViewed(), isTrue);
    expect(find.byType(OnboardingView), findsNothing);
    // A subsequent launch skips the intro.
    AppRouter.router.go(AppRouter.root);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await settle();
    expect(find.byType(OnboardingView), findsNothing);

    expect(find.text('Choose your role'), findsOneWidget);
    await capture('02_choose_role');
    await tester.tap(find.text('Client'));
    await settle();
    expect(find.text('Continue as Client'), findsOneWidget);
    await tester.tap(find.text('Continue as Client'));
    await settle();
    expect(
      tester.widget<SignInView>(find.byType(SignInView)).role.name,
      'client',
    );
    await capture('03_sign_in');

    await tester.tap(find.text('Forget Password?'));
    await settle();
    expect(
      tester
          .widget<ForgotPasswordView>(find.byType(ForgotPasswordView))
          .role
          .name,
      'client',
    );
    await capture('11_forgot_password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await settle();
    expect(find.text('Email is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'bad-email');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await settle();
    expect(find.text('Invalid email address'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      '  recovery@example.com  ',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await settle();
    expect(find.text('Preview password recovery'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle();
    expect(find.byType(ForgotPasswordView), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await settle();
    await tester.tap(find.text('Preview OTP'));
    await settle();
    final recovery = tester.widget<OtpView>(find.byType(OtpView)).request;
    expect(recovery.email, 'recovery@example.com');
    expect(recovery.role.name, 'client');
    await capture('12_otp');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Done'));
    await settle();
    expect(find.text('Enter the 5-digit verification code.'), findsOneWidget);
    await tester.enterText(find.byType(Pinput), '12a');
    await settle();
    expect(tester.widget<Pinput>(find.byType(Pinput)).controller!.text, '12');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Done'));
    await settle();
    expect(find.text('Enter the 5-digit verification code.'), findsOneWidget);
    await tester.enterText(find.byType(Pinput), '12345');
    await settle();
    expect(find.text('Enter the 5-digit verification code.'), findsNothing);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Done'));
    await settle();
    expect(
      find.text(
        'Code verification is not connected yet. No code has been verified and your password has not changed.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirm'));
    await settle();
    await tester.tap(find.widgetWithText(TextButton, 'Resend'));
    await settle();
    expect(
      find.text('Code delivery is not connected yet. No code has been sent.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirm'));
    await settle();
    expect(sl<AppPreferences>().getResetPasswordToken(), isEmpty);
    expect(sl<AppPreferences>().getVerificationToken(), isEmpty);
    expect(sl<AppPreferences>().isLoggedIn, isFalse);
    AppRouter.router.pop();
    await settle();
    expect(find.byType(ForgotPasswordView), findsOneWidget);
    AppRouter.router.pop();
    await settle();
    expect(
      tester.widget<SignInView>(find.byType(SignInView)).role.name,
      'client',
    );

    await tester.tap(find.widgetWithText(TextButton, 'Sign up'));
    await settle();
    expect(
      tester.widget<SignUpView>(find.byType(SignUpView)).role.name,
      'client',
    );
    expect(find.byType(TextFormField), findsNWidgets(4));
    await capture('08_create_account');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
    await settle();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('This field is required'), findsNWidgets(3));
    await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
    await tester.enterText(find.byType(TextFormField).at(1), 'invalid');
    await tester.enterText(find.byType(TextFormField).at(2), 'short');
    await tester.enterText(find.byType(TextFormField).at(3), 'different');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Sign up'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
    await settle();
    expect(find.text('Invalid email address'), findsOneWidget);
    expect(find.text('Field must be at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.enterText(find.byType(TextFormField).at(3), 'password123');
    await tester.ensureVisible(find.byTooltip('Show password: Password'));
    await tester.tap(find.byTooltip('Show password: Password'));
    await settle();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(3)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Show password: Confirm Password'));
    await settle();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(3)).obscureText,
      isFalse,
    );
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Sign up'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
    await settle();
    expect(
      find.text(
        'Account creation is not connected yet. Your details have not been sent and no account has been created.',
      ),
      findsOneWidget,
    );
    expect(sl<AppPreferences>().isLoggedIn, isFalse);
    await tester.tap(find.text('Confirm'));
    await settle();
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Sign in'));
    await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
    await settle();
    expect(find.byType(SignInView), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await settle();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('This field is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'bad-email');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await settle();
    expect(find.text('Invalid email address'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.byTooltip('Show password'));
    await settle();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isFalse,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await settle();
    expect(find.text('Preview the design'), findsOneWidget);
    await tester.tap(find.text('Preview dashboard'));
    await settle();
    expect(sl<AppPreferences>().isLoggedIn, isFalse);
    expect(find.text('Your Profile Is Being Reviewed'), findsOneWidget);
    // Capture all dashboard content at the Figma frame height.
    tester.view.physicalSize = const Size(390, 1260);
    await settle();
    await capture('04_home');
    await tester.ensureVisible(
      find.text('How long does the review process take?'),
    );
    await tester.tap(find.text('How long does the review process take?'));
    await settle();
    expect(
      find.text(
        "Review times vary. You'll be notified when your application status changes.",
      ),
      findsOneWidget,
    );
    final router = AppRouter.router;
    await tester.tap(find.byTooltip('Menu'));
    await settle();
    await tester.tap(find.byType(LanguageToggleButton));
    await settle();
    expect(sl<AppPreferences>().getAppLanguage(), 'ar');
    expect(identical(AppRouter.router, router), isTrue);
    Navigator.of(tester.element(find.byType(LanguageToggleButton))).pop();
    tester.view.physicalSize = const Size(320, 640);
    await settle();
    await capture('05_home_arabic_small');
    expect(tester.takeException(), isNull);
    AppRouter.router.go(AppRouter.chooseRole);
    await settle();
    expect(find.text('اختر دورك'), findsOneWidget);
    await capture('06_role_arabic_small');
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('المتابعة كـ موهبة'));
    await settle();
    await capture('07_sign_in_arabic_small');
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.widgetWithText(TextButton, 'سجّل الآن'));
    await tester.tap(find.widgetWithText(TextButton, 'سجّل الآن'));
    await settle();
    expect(find.text('إنشاء حساب'), findsOneWidget);
    await capture('09_create_account_arabic_small');
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'سجّل الآن'),
    );
    await settle();
    await capture('10_create_account_arabic_bottom');
    expect(tester.takeException(), isNull);

    AppRouter.router.go(AppRouter.forgotPassword);
    await settle();
    await capture('13_forgot_password_arabic_small');
    await tester.enterText(find.byType(TextFormField), 'arabic@example.com');
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'reset_password_action'.tr()),
    );
    await settle();
    await tester.tap(find.text('preview_otp'.tr()));
    await settle();
    await capture('14_otp_arabic_small');
    await tester.enterText(
      find.byType(Pinput),
      '\u0661\u0662\u0663\u0664\u0665',
    );
    await settle();
    expect(
      tester.widget<Pinput>(find.byType(Pinput)).controller!.text,
      '12345',
    );
    await capture('15_otp_arabic_entered');
    await tester.enterText(find.byType(Pinput), '123');
    await settle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'otp_done'.tr()));
    await settle();
    expect(find.text('otp_invalid'.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Reloading or opening OTP without a recovery request returns to the email form.
    AppRouter.router.go(AppRouter.otp);
    await settle();
    expect(find.byType(ForgotPasswordView), findsOneWidget);

    AppRouter.router.go(AppRouter.onboarding);
    await settle();
    await capture('19_intro_opportunities_arabic_small');
    for (var page = 0; page < 2; page++) {
      final next = find
          .widgetWithText(ElevatedButton, 'intro_next'.tr())
          .hitTestable();
      // Scroll each short viewport vertically until its action is reachable.
      final currentButton = find.widgetWithText(
        ElevatedButton,
        'intro_next'.tr(),
      );
      await tester.ensureVisible(currentButton.first);
      await settle();
      await tester.tap(next.first);
      await settle();
      await capture(
        page == 0
            ? '20_intro_team_arabic_small'
            : '21_intro_dashboard_arabic_small',
      );
      expect(tester.takeException(), isNull);
    }
    final start = find.widgetWithText(ElevatedButton, 'intro_get_started'.tr());
    await tester.ensureVisible(start);
    await settle();
    await tester.tap(start);
    await settle();
    expect(find.byType(OnboardingView), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await sl.reset();
  });
}
