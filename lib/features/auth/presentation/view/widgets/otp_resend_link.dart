import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/resources/qader_design.dart';

/// "Didn't receive the code? Resend" under a code field, as in the client
/// Figma frames.
class OtpResendLink extends StatelessWidget {
  const OtpResendLink({super.key, required this.onPressed});

  /// Null while a request is running.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        'otp_no_code'.tr(context: context),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'otp_resend'.tr(context: context),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: QaderDesign.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ],
  );
}
