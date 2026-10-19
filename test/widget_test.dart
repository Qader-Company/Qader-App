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
    'Figma flow, validation, preview, FAQ, and Arabic on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      AppEnv.init(Environment.dev, splashDuration: const Duration(seconds: 1));
      await EasyLocalization.ensureInitialized();
      await initServiceLocator();
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
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)),
        );
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

      await capture('01_splash');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Choose your role'), findsOneWidget);
      await capture('02_choose_role');
      await tester.tap(find.text('Client'));
      await tester.pumpAndSettle();
      expect(find.text('Continue as Client'), findsOneWidget);
      await tester.tap(find.text('Continue as Client'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SignInView>(find.byType(SignInView)).role.name,
        'client',
      );
      await capture('03_sign_in');
      await tester.tap(find.widgetWithText(TextButton, 'Sign up'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SignUpView>(find.byType(SignUpView)).role.name,
        'client',
      );
      expect(find.byType(TextFormField), findsNWidgets(4));
      await capture('08_create_account');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('This field is required'), findsNWidgets(3));
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid');
      await tester.enterText(find.byType(TextFormField).at(2), 'short');
      await tester.enterText(find.byType(TextFormField).at(3), 'different');
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Sign up'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid email address'), findsOneWidget);
      expect(find.text('Field must be at least 8 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'new@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.ensureVisible(find.byTooltip('Show password: Password'));
      await tester.tap(find.byTooltip('Show password: Password'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
        isFalse,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(3)).obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('Show password: Confirm Password'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(3)).obscureText,
        isFalse,
      );
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Sign up'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Account creation is not connected yet. Your details have not been sent and no account has been created.',
        ),
        findsOneWidget,
      );
      expect(sl<AppPreferences>().isLoggedIn, isFalse);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Sign in'));
      await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInView), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('This field is required'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'bad-email');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid email address'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isFalse,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('Preview the design'), findsOneWidget);
      await tester.tap(find.text('Preview dashboard'));
      await tester.pumpAndSettle();
      expect(sl<AppPreferences>().isLoggedIn, isFalse);
      expect(find.text('Your Profile Is Being Reviewed'), findsOneWidget);
      // Capture all dashboard content at the Figma frame height.
      tester.view.physicalSize = const Size(390, 1260);
      await tester.pumpAndSettle();
      await capture('04_home');
      await tester.ensureVisible(
        find.text('How long does the review process take?'),
      );
      await tester.tap(find.text('How long does the review process take?'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "Review times vary. You'll be notified when your application status changes.",
        ),
        findsOneWidget,
      );
      final router = AppRouter.router;
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LanguageToggleButton));
      await tester.pumpAndSettle();
      expect(sl<AppPreferences>().getAppLanguage(), 'ar');
      expect(identical(AppRouter.router, router), isTrue);
      Navigator.of(tester.element(find.byType(LanguageToggleButton))).pop();
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      await capture('05_home_arabic_small');
      expect(tester.takeException(), isNull);
      AppRouter.router.go(AppRouter.chooseRole);
      await tester.pumpAndSettle();
      expect(find.text('اختر دورك'), findsOneWidget);
      await capture('06_role_arabic_small');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('المتابعة كـ موهبة'));
      await tester.pumpAndSettle();
      await capture('07_sign_in_arabic_small');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.widgetWithText(TextButton, 'سجّل الآن'));
      await tester.tap(find.widgetWithText(TextButton, 'سجّل الآن'));
      await tester.pumpAndSettle();
      expect(find.text('إنشاء حساب'), findsOneWidget);
      await capture('09_create_account_arabic_small');
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'سجّل الآن'),
      );
      await tester.pumpAndSettle();
      await capture('10_create_account_arabic_bottom');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await sl.reset();
    },
  );
}
