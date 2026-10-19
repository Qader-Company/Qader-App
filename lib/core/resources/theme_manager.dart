import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'color_manager.dart';
import 'font_manager.dart';
import 'styles_manager.dart';

class ThemeManager {
  static ThemeData getTheme() {
    return ThemeData(
      fontFamily: FontConstants.fontFamily,
      colorScheme: ColorScheme.fromSeed(seedColor: ColorManager.primary),
      scaffoldBackgroundColor: ColorManager.white,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        surfaceTintColor: ColorManager.white,
        scrolledUnderElevation: 1,
        shadowColor: ColorManager.greyBorder,
        backgroundColor: ColorManager.white,
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size.zero)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: getRegularStyle(color: ColorManager.grey, fontSize: 12.sp),
        labelStyle: getMediumStyle(
          color: ColorManager.textColor,
          fontSize: 14.sp,
        ),
        fillColor: ColorManager.white,
        filled: true,
        contentPadding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: ColorManager.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: ColorManager.greyBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: ColorManager.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: ColorManager.red),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: ColorManager.grey),
        ),
      ),
    );
  }
}
