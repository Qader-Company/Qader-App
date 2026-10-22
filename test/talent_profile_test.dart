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
import 'package:qader/app/env/app_env.dart';
import 'package:qader/core/di/service_locator.dart';
import 'package:qader/core/locale/language_manager.dart';
import 'package:qader/core/router/app_router.dart';
import 'package:qader/features/talent_profile/presentation/view/talent_profile_view.dart';
import 'package:qader/features/talent_profile/presentation/view/profile_review_view.dart';

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
    'Talent profile tabs, availability, local edits, review and Arabic layout',
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
      AppRouter.router.go(AppRouter.home);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(TalentProfileView), findsOneWidget);
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name, double height) async {
        tester.view.physicalSize = Size(390, height);
        await tester.pumpAndSettle();
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)),
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
        expect(tester.takeException(), isNull);
      }

      await capture('talent_basic', 1807);
      await tap(find.byType(Switch));
      expect(tester.widget<Switch>(find.byType(Switch)).value, false);
      await tap(find.byKey(const ValueKey('profile_tab_1')));
      expect(find.text('Qader Talent Portal'), findsNWidgets(2));
      expect(tester.widget<Switch>(find.byType(Switch)).value, false);
      await capture('talent_skills', 1878);
      await tap(find.byKey(const ValueKey('profile_tab_2')));
      expect(find.text('8,000–12,000 USD'), findsOneWidget);
      await capture('talent_work', 1334);
      await tap(find.text('Olivia_Rhye_CV_2026.pdf'));
      expect(
        find.text('This preview does not include an uploaded CV file'),
        findsOneWidget,
      );
      await tap(find.text('Confirm'));
      await tap(find.widgetWithText(ElevatedButton, 'Edit Profile'));
      final name = find.byWidgetPredicate(
        (w) => w is TextFormField && w.controller?.text == 'Muhamed Bayomee',
      );
      await tester.enterText(name, '');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      expect(find.text('This field is required'), findsOneWidget);
      final nameField = find.byType(TextFormField).at(1);
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Ahmed Ali');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      expect(find.text('Ahmed Ali'), findsOneWidget);
      await tap(find.widgetWithText(OutlinedButton, 'Evaluation'));
      expect(find.byType(ProfileReviewView), findsOneWidget);
      await capture('talent_review', 1334);
      await tap(find.widgetWithText(ElevatedButton, 'Buy the Review Now'));
      expect(
        find.text(
          'Purchasing is not connected yet and no payment has been taken',
        ),
        findsOneWidget,
      );
      await tap(find.text('Confirm'));
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Ahmed Ali'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, false);
      await tester
          .element(find.byType(TalentProfileView))
          .setLocale(arabicLocale);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 844);
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tap(find.byKey(ValueKey('profile_tab_$i')));
        expect(tester.takeException(), isNull);
      }
      await tap(find.widgetWithText(OutlinedButton, 'التقييم'));
      expect(find.text('احصل على مراجعة احترافية لملفك'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
