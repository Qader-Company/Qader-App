import 'package:qader/core/storage/app_preferences.dart';
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
import 'package:qader/features/talent_profile/presentation/view/profile_evaluation_view.dart';
import 'package:qader/features/talent_profile/presentation/widgets/evaluation_report_widgets.dart';
import 'package:qader/features/talent_profile/presentation/widgets/profile_reevaluation_countdown.dart';
import 'package:qader/features/talent_profile/presentation/widgets/restricted_profile_notice.dart';
import 'package:qader/features/talent_profile/presentation/widgets/profile_sections.dart';

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
    'Report accordions and rejected and restricted profile previews',
    (tester) async {
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

      await tap(find.byTooltip('Menu'));
      await tap(find.text('Profile previews'));
      await tap(find.text('Rejected profile'));
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.byType(ProfileReevaluationCountdown), findsOneWidget);
      expect(find.byType(ProfileBasicInfo), findsNothing);
      await capture('talent_rejected', 922);
      await tap(find.widgetWithText(ElevatedButton, 'Edit Profile'));
      await tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      expect(find.text('Rejected'), findsOneWidget);
      AppRouter.router.go('${AppRouter.talentProfile}?status=restricted');
      await tester.pumpAndSettle();
      expect(find.text('Profile Restricted'), findsOneWidget);
      expect(find.byType(RestrictedProfileNotice), findsOneWidget);
      await capture('talent_restricted', 1032);
      await tap(find.widgetWithText(OutlinedButton, 'Evaluation'));
      expect(find.byType(ProfileEvaluationView), findsOneWidget);
      expect(find.byType(EvaluationMetricCard), findsNWidgets(4));
      await capture('talent_evaluation', 2718);
      await tap(find.text('See Recommendations (30%)'));
      expect(find.text('Hide Recommendations'), findsOneWidget);
      await tap(find.text('Collapse all'));
      expect(find.byType(EvaluationMetricCard), findsNothing);
      await capture('talent_evaluation_collapsed', 922);
      await tap(find.text('Expand all'));
      expect(find.byType(EvaluationMetricCard), findsNWidgets(6));
      await tap(find.widgetWithText(ElevatedButton, 'Profile Review'));
      expect(find.byType(EvaluationMetricCard), findsNWidgets(2));
      await tester
          .element(find.byType(ProfileEvaluationView))
          .setLocale(arabicLocale);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 844);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tap(find.widgetWithText(ElevatedButton, 'مراجعة الملف'));
      expect(find.byType(EvaluationMetricCard), findsNWidgets(6));
      AppRouter.router.go('${AppRouter.talentProfile}?status=restricted');
      await tester.pumpAndSettle();
      expect(find.byType(RestrictedProfileNotice), findsOneWidget);
      expect(tester.takeException(), isNull);
      AppRouter.router.go(AppRouter.talentProfile);
      await tester.pumpAndSettle();
      expect(find.byType(RestrictedProfileNotice), findsNothing);
      expect(find.byType(ProfileBasicInfo), findsOneWidget);
      expect(find.byType(ProfileReevaluationCountdown), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
