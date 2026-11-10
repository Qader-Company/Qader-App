import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/resources/qader_design.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/features/home/presentation/status_copy.dart';
import 'package:qader/features/home/presentation/view/application_status_view.dart';

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
  for (final locale in [const Locale('en', 'US'), const Locale('ar', 'SA')]) {
    testWidgets('status previews render and slot actions work in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = Size(
        locale.languageCode == 'en' ? 390 : 320,
        1260,
      );
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      for (final family in ['Poppins', 'Rubik']) {
        final loader = FontLoader(family);
        for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
          loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
        }
        await loader.load();
      }
      final captureKey = GlobalKey();
      Future<void> mount(ApplicationStatus status) async {
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
            startLocale: locale,
            saveLocale: false,
            path: 'assets/translations',
            assetLoader: const _Translations(),
            child: Builder(
              builder: (context) => MaterialApp(
                theme: QaderDesign.apply(ThemeData(), context.locale),
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: RepaintBoundary(
                  key: captureKey,
                  child: ApplicationStatusView(
                    key: ValueKey(status),
                    initialStatus: status,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      for (final status in ApplicationStatus.values) {
        await mount(status);
        expect(tester.takeException(), isNull, reason: status.name);
        await tester.runAsync(() async {
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'build/design_review/status_${status.name}_${locale.languageCode}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -900),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${status.name} scrolled',
        );
      }
      if (locale.languageCode == 'en') {
        await mount(ApplicationStatus.slots);
        await tester.tap(find.byKey(const ValueKey('slot-1')));
        await tester.tap(find.text('Confirm Selected Slot'));
        await tester.pumpAndSettle();
        expect(find.text('Interview Confirmed!'), findsOneWidget);
        expect(find.text('View Location'), findsOneWidget);
        await tester.tap(find.byTooltip('More actions'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel meeting'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Keep My Slot'));
        await tester.pumpAndSettle();
        expect(find.text('Interview Confirmed!'), findsOneWidget);
        await tester.tap(find.byTooltip('More actions'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel meeting'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes, Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm Selected Slot'), findsOneWidget);
        await tester.tap(find.text('Confirm Selected Slot'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('More actions'), findsNothing);
        await mount(ApplicationStatus.newSlots);
        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Reject all slots'),
        );
        await tester.pumpAndSettle();
        expect(find.text('10 more characters required'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Submit Rejection'),
          findsNothing,
        );
        await tester.enterText(
          find.byType(TextField),
          'I have a prior appointment.',
        );
        await tester.pump();
        await tester.tap(find.text('Submit Rejection'));
        await tester.pumpAndSettle();
        expect(find.text('No available slots at the moment'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
