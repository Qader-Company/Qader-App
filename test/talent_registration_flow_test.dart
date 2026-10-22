import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/app/app.dart';
import 'package:qader/app/env/app_env.dart';
import 'package:qader/core/di/service_locator.dart';
import 'package:qader/core/locale/language_manager.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/auth/presentation/view/sign_in_view.dart';
import 'package:qader/features/auth/presentation/view/sign_up_view.dart';
import 'package:qader/features/profile_setup/presentation/view/profile_setup_view.dart';
import 'package:qader/features/profile_setup/presentation/widgets/basic_info_step.dart';

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File(
              '$path/${locale.languageCode}-${locale.countryCode!}.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Talent registration preserves its role and seeds the profile preview',
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
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
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

      AppRouter.router.go(AppRouter.chooseRole);
      await tester.pumpAndSettle();
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await tap(find.text('Continue as Talent'));
      expect(
        tester.widget<SignInView>(find.byType(SignInView)).role.name,
        'talent',
      );
      await tap(find.widgetWithText(TextButton, 'Sign up'));
      for (final entry in [
        (0, '  Ahmed Talent  '),
        (1, '  talent@example.com  '),
        (2, 'password123'),
        (3, 'password123'),
      ]) {
        await tester.enterText(
          find.byType(TextFormField).at(entry.$1),
          entry.$2,
        );
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tap(find.text('Confirm'));
      expect(find.byType(SignUpView), findsOneWidget);
      expect(find.byType(ProfileSetupView), findsNothing);
      await tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tap(find.text('Preview talent profile'));
      expect(find.byType(ProfileSetupView), findsOneWidget);
      await tap(find.widgetWithText(ElevatedButton, 'Continue'));
      final draft = tester
          .widget<BasicInfoStep>(find.byType(BasicInfoStep))
          .draft;
      expect(draft.text('name').text, 'Ahmed Talent');
      expect(draft.text('email').text, 'talent@example.com');
      expect(sl<AppPreferences>().isLoggedIn, isFalse);
      await tap(find.byTooltip('Back'));
      await tap(find.byTooltip('Back'));
      expect(find.byType(SignUpView), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(0))
            .controller!
            .text
            .trim(),
        'Ahmed Talent',
      );
      await tap(find.widgetWithText(TextButton, 'Sign in'));
      expect(
        tester.widget<SignInView>(find.byType(SignInView)).role.name,
        'talent',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
