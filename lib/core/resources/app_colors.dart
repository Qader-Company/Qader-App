import 'package:flutter/material.dart';

/// The single source of truth for colors, taken from the Qader Figma file.
///
/// The design uses the Tailwind scales, so neutrals and status colors keep
/// their Tailwind names (`neutral500`, `green700`, …). Use these tokens (or
/// the theme built from them) instead of writing `Color(0x…)` in widgets.
abstract final class AppColors {
  // ─── Brand ───
  static const primary = Color(0xFF0A32DB);
  static const primaryNavy = Color(0xFF0A1F6B);
  static const blue = Color(0xFF346AE8);
  static const blueStrong = Color(0xFF1D52E5);
  static const blueLight = Color(0xFFB8D0FF);
  static const blueBorder = Color(0xFFB4CBF6);
  static const blueDisabled = Color(0xFFD5E0FA);
  static const blueSoft = Color(0xFFE8EFFC);
  static const paleBlue = Color(0xFFF4F8FE);

  // ─── Neutrals (Tailwind neutral) ───
  static const white = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral400 = Color(0xFFA3A3A3);
  static const neutral500 = Color(0xFF737373);
  static const neutral600 = Color(0xFF525252);
  static const neutral700 = Color(0xFF404040);
  static const neutral800 = Color(0xFF262626);
  static const neutral900 = Color(0xFF171717);

  // ─── Surfaces ───
  /// Page background behind cards.
  static const background = Color(0xFFF7F7F7);
  static const surfaceMuted = Color(0xFFF0F0F0);

  // ─── Semantic aliases ───
  static const textPrimary = neutral900;
  static const textBody = neutral700;
  static const textSecondary = neutral600;
  static const textMuted = neutral500;
  static const border = neutral300;
  static const divider = neutral200;

  // ─── Success (green) ───
  static const green50 = Color(0xFFF0FDF4);
  static const green100 = Color(0xFFDCFCE7);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);
  static const green700 = Color(0xFF008236);

  // ─── Warning (yellow / amber / orange) ───
  static const yellow50 = Color(0xFFFEFCE8);
  static const yellow100 = Color(0xFFFEF9C3);
  static const yellow600 = Color(0xFFCA8A04);
  static const yellow700 = Color(0xFFA16207);
  static const amber400 = Color(0xFFFBBF24);
  static const amber500 = Color(0xFFF59E0B);
  static const orange500 = Color(0xFFF97316);

  // ─── Danger (red) ───
  static const red50 = Color(0xFFFEF2F2);
  static const red100 = Color(0xFFFEE2E2);
  static const red300 = Color(0xFFFCA5A5);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  static const red900 = Color(0xFF7F1D1D);

  /// Brand red used by "restricted" profile notices.
  static const alertRed = Color(0xFFEF232A);

  // ─── Accent (purple) ───
  static const purple50 = Color(0xFFFAF5FF);
  static const purple600 = Color(0xFF9333EA);

  // ─── Overlays & shadows ───
  /// Dialog barrier (Figma: #2D2C2C at 59%).
  static const barrier = Color(0x962D2C2C);
  static const white80 = Color(0xCCFFFFFF);
  static const shadow20 = Color(0x33000000);
  static const shadow5 = Color(0x0D000000);
  static const blueStrong10 = Color(0x1A1D52E5);
}
