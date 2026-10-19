import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../resources/color_manager.dart';
import '../resources/styles_manager.dart';

/// Shows a prompt asking the user to login.
class GoLoginWidget extends StatelessWidget {
  final String message;
  final VoidCallback onLogin;

  const GoLoginWidget({
    super.key,
    required this.onLogin,
    this.message = 'Please login to continue',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64.sp, color: ColorManager.grey),
            SizedBox(height: 16.h),
            Text(
              message,
              style: getRegularStyle(
                fontSize: 14.sp,
                color: ColorManager.greyText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: ColorManager.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              ),
              child: Text(
                'Login',
                style: getBoldStyle(fontSize: 14.sp, color: ColorManager.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
