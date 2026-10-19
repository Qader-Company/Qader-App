import 'package:flutter/material.dart';

class ColorManager {
  ColorManager._();

  // ─── Primary ───
  static const Color primary = Color(0xff2563EB);
  static const Color primaryLight = Color(0xffDDDEFB);
  static const Color primaryDark = Color(0xff1A4DBF);

  // ─── Gradient ───
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ─── Neutrals ───
  static const Color white = Color(0xffffffff);
  static const Color black = Color(0xff1a1a1a);
  static const Color bg = Color(0xffF3F4F5);
  static const Color lightBg = Color(0xffF9FAFB);

  // ─── Text ───
  static const Color textColor = Color(0xff202244);
  static const Color greyText = Color(0xff717579);
  static const Color lightGreyText = Color(0xffB4B4B4);
  static const Color hintText = Color(0xffB7B7B7);

  // ─── Borders ───
  static const Color greyBorder = Color(0xffE1E2E5);
  static const Color divider = Color(0xffd8d8d8);

  // ─── Status ───
  static const Color red = Color(0xffE90000);
  static const Color green = Color(0xff2a9946);
  static const Color yellow = Color(0xffF4B400);
  static const Color blue = Color(0xff4E74F9);

  // ─── Status Backgrounds ───
  static const Color successBg = Color(0xffE8F5E9);
  static const Color successText = Color(0xff2E7D32);
  static const Color errorBg = Color(0xffFFEBEE);
  static const Color errorText = Color(0xffC62828);
  static const Color warningBg = Color(0xffFFF3E0);
  static const Color warningText = Color(0xffEF6C00);
  static const Color infoBg = Color(0xffE3F2FD);
  static const Color infoText = Color(0xff1565C0);

  // ─── Shimmer ───
  static const Color shimmerBase = Color(0xfff2f4f5);
  static const Color shimmerHighlight = Color(0xffffffff);

  // ─── Others ───
  static const Color fillColor = Color(0xffF7F8F9);
  static const Color grey = Color(0xff999DAF);

  // ─── Wallet ───
  static const Color walletPrimary = Color(0xFF38B6FF);
  static const Color walletPrimaryDark = Color(0xFF0288D1);
  static const Color walletBorder = Color(0xFFE2E8F0);
  static const Color walletSubtleText = Color(0xFF64748B);
  static const Color walletHintText = Color(0xFF94A3B8);
  static const Color walletSuccess = Color(0xFF10B981);
  static const Color walletChipGold = Color(0xFFFFD54F);
}
