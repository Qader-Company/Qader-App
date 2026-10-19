import 'dart:ui';

const String assetPathLanguage = 'assets/translations';
const Locale arabicLocale = Locale('ar', 'SA');
const Locale englishLocale = Locale('en', 'US');

enum LanguageType {
  arabic('ar'),
  english('en');

  final String code;
  const LanguageType(this.code);
}
