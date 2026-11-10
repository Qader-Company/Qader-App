import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
export 'app_colors.dart';

/// Screen theme for the Figma screens. Colors come from [AppColors].
abstract class QaderDesign {
  static const primary = AppColors.primary;
  static const blue = AppColors.blue;
  static const paleBlue = AppColors.paleBlue;
  static const ink = AppColors.textPrimary;
  static const muted = AppColors.textSecondary;
  static const border = AppColors.border;

  /// Figma typography and inputs on top of the ambient theme.
  static ThemeData theme(BuildContext context) =>
      apply(Theme.of(context), context.locale);

  /// Applies the Figma typography (Poppins / Rubik for Arabic), text colors
  /// and input style to [base]. Idempotent.
  static ThemeData apply(ThemeData base, Locale locale) {
    final font = locale.languageCode == 'ar' ? 'Rubik' : 'Poppins';
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
          color: AppColors.neutral500,
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
