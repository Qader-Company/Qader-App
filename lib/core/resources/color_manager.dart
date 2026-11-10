import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Legacy names used by the shared widgets in `core/widgets`. Every value
/// points at [AppColors] (the Figma palette); prefer [AppColors] in new code.
class ColorManager {
  ColorManager._();

  // ─── Primary ───
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryNavy;

  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ─── Neutrals ───
  static const Color white = AppColors.white;
  static const Color black = AppColors.neutral900;
  static const Color bg = AppColors.background;
  static const Color lightBg = AppColors.neutral50;
  static const Color fillColor = AppColors.neutral50;

  // ─── Text ───
  static const Color textColor = AppColors.textPrimary;
  static const Color greyText = AppColors.textMuted;
  static const Color hintText = AppColors.neutral400;

  // ─── Borders ───
  static const Color greyBorder = AppColors.divider;
  static const Color grey = AppColors.neutral400;

  // ─── Status ───
  static const Color red = AppColors.red600;
  static const Color green = AppColors.green600;
  static const Color successText = AppColors.green700;
  static const Color successBg = AppColors.green100;
  static const Color errorText = AppColors.red600;
  static const Color errorBg = AppColors.red100;
  static const Color warningText = AppColors.yellow700;
  static const Color warningBg = AppColors.yellow50;

  // ─── Shimmer ───
  static const Color shimmerBase = AppColors.neutral100;
  static const Color shimmerHighlight = AppColors.white;
}
