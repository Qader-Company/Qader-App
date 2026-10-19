import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';
import '../resources/color_manager.dart';
import '../resources/styles_manager.dart';

class AppFunctions {
  static void showToast(
    BuildContext context,
    String text, {
    bool isError = false,
    int seconds = 5,
  }) {
    toastification.show(
      context: context,
      type: isError ? ToastificationType.error : ToastificationType.success,
      style: ToastificationStyle.minimal,
      description: Text(
        text,
        style: getRegularStyle(fontSize: 13.sp, color: ColorManager.greyText),
      ),
      alignment: AlignmentDirectional.topEnd,
      autoCloseDuration: Duration(seconds: seconds),
      borderRadius: BorderRadius.circular(5.r),
      boxShadow: highModeShadow,
      dragToClose: true,
      direction: ui.TextDirection.ltr,
    );
  }

  static void copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(context, 'copied_to_clipboard'.tr());
  }

  static void showConfirmDialog(
    BuildContext context, {
    required String title,
    String? description,
    bool isDanger = false,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          decoration: BoxDecoration(
            color: ColorManager.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 6.h,
                decoration: BoxDecoration(
                  color: isDanger ? ColorManager.red : ColorManager.primary,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color:
                            (isDanger ? ColorManager.red : ColorManager.primary)
                                .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDanger
                            ? Icons.warning_amber_rounded
                            : Icons.help_outline_rounded,
                        color: isDanger
                            ? ColorManager.red
                            : ColorManager.primary,
                        size: 36.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      title,
                      style: getBoldStyle(
                        fontSize: 16.sp,
                        color: ColorManager.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (description != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        description,
                        style: getRegularStyle(
                          fontSize: 13.sp,
                          color: ColorManager.greyText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: ColorManager.greyBorder,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'cancel'.tr(),
                              style: getBoldStyle(
                                fontSize: 13.sp,
                                color: ColorManager.greyText,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onConfirm?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDanger
                                  ? ColorManager.red
                                  : ColorManager.primary,
                              foregroundColor: ColorManager.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'confirm'.tr(),
                              style: getBoldStyle(
                                fontSize: 13.sp,
                                color: ColorManager.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showModalSheet(
    BuildContext context, {
    required List<Widget> children,
    bool isDismissible = true,
  }) {
    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: isDismissible,
      context: context,
      builder: (_) => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
        decoration: BoxDecoration(
          color: ColorManager.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40.r),
            topRight: Radius.circular(40.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            SizedBox(height: 15.h),
            ...children,
          ],
        ),
      ),
    );
  }
}
