import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/resources/theme_manager.dart';
import 'package:qader/core/widgets/default_button.dart';
import 'package:qader/core/widgets/default_dropdown.dart';
import 'package:qader/core/widgets/default_form_field.dart';

void main() {
  /// Font family the text [text] is drawn with.
  String? family(WidgetTester tester, String text) => tester
      .widget<RichText>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      )
      .text
      .style
      ?.fontFamily;

  for (final (locale, expected) in const [
    (Locale('en', 'US'), 'Poppins'),
    (Locale('ar', 'SA'), 'Rubik'),
  ]) {
    testWidgets('every shared widget uses $expected for $locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            theme: ThemeManager.getTheme(locale),
            home: Scaffold(
              body: Column(
                children: [
                  const Text('Plain text'),
                  // The full-size variants used to force Rubik.
                  DefaultButton(text: 'Full button', onPressed: () {}),
                  const DefaultFormField(label: 'Full field'),
                  DefaultDropdown<String>(
                    label: 'Full dropdown',
                    items: const ['One'],
                    itemLabel: (value) => value,
                  ),
                  DefaultButton.compact(text: 'Compact', onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      for (final text in [
        'Plain text',
        'Full button',
        'Full field',
        'Full dropdown',
        'Compact',
      ]) {
        expect(family(tester, text), expected, reason: text);
      }
    });
  }
}
