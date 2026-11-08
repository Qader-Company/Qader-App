import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/widgets/qader_design.dart';
import 'package:qader/features/profile_setup/presentation/widgets/profile_phone_input.dart';

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
    testWidgets('phone country selection, restore and narrow layout $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
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
      final phoneCode = TextEditingController();
      final phone = TextEditingController(text: '1012345678');
      final whatsappCode = TextEditingController(text: '+966');
      final whatsapp = TextEditingController(text: '501234567');
      final form = GlobalKey<FormState>();
      final capture = GlobalKey();
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
          startLocale: locale,
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _Translations(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: [
                ...context.localizationDelegates,
                CountryLocalizations.delegate,
              ],
              home: QaderTheme(
                child: Scaffold(
                  body: RepaintBoundary(
                    key: capture,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: form,
                        child: Column(
                          children: [
                            ProfilePhoneInput(
                              label: 'Phone Number',
                              codeController: phoneCode,
                              numberController: phone,
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 16),
                            ProfilePhoneInput(
                              label: 'WhatsApp Number',
                              codeController: whatsappCode,
                              numberController: whatsapp,
                              validator: (_) => null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SA +966'), findsOneWidget);
      expect(form.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('profile_select_country'.tr()), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('Phone Number-country')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        locale.languageCode == 'ar' ? 'مصر' : 'Egypt',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(locale.languageCode == 'ar' ? 'مصر' : 'Egypt').last,
      );
      await tester.pumpAndSettle();
      expect(phoneCode.text, '+20');
      expect(phone.text, '1012345678');
      expect(whatsappCode.text, '+966');
      expect(form.currentState!.validate(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('EG +20'), findsOneWidget);
      // Cancel leaves the existing value intact.
      await tester.tap(find.byKey(const ValueKey('WhatsApp Number-country')));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(whatsappCode.text, '+966');
      // Server restoration must refresh the displayed calling code.
      phoneCode.text = '+44';
      await tester.pumpAndSettle();
      expect(find.textContaining('+44'), findsOneWidget);
      phoneCode.text = '+1';
      await tester.pumpAndSettle();
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('US +1'), findsNothing);
      expect(tester.takeException(), isNull);
      phoneCode.text = '+20';
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/phone-preview').create(recursive: true);
        await File(
          'build/phone-preview/${locale.languageCode}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      for (final controller in [phoneCode, phone, whatsappCode, whatsapp]) {
        controller.dispose();
      }
    });
  }
}
