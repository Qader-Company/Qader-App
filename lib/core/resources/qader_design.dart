import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

abstract class QaderDesign {
  static const primary = Color(0xFF0A32DB);
  static const blue = Color(0xFF346AE8);
  static const paleBlue = Color(0xFFF4F8FE);
  static const ink = Color(0xFF171717);
  static const muted = Color(0xFF525252);
  static const border = Color(0xFFD4D4D4);

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final font = context.locale.languageCode == 'ar' ? 'Rubik' : 'Poppins';
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: font,
        bodyColor: ink,
        displayColor: ink,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: font),
      colorScheme: base.colorScheme.copyWith(primary: primary),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(
          fontFamily: font,
          fontSize: 14,
          color: const Color(0xFF737373),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
    );
  }
}
