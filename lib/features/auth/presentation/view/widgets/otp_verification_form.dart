import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/helpers/feature_dialog.dart';
import '../../../../../core/resources/qader_design.dart';
import '../../../../../core/widgets/default_button.dart';
import '../../../domain/entities/password_recovery_request.dart';
import 'otp_code_field.dart';

class OtpVerificationForm extends StatefulWidget {
  const OtpVerificationForm({super.key, required this.request});
  final PasswordRecoveryRequest request;

  @override
  State<OtpVerificationForm> createState() => _OtpVerificationFormState();
}

class _OtpVerificationFormState extends State<OtpVerificationForm> {
  final _code = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!RegExp(r'^[0-9]{5}$').hasMatch(_code.text)) {
      setState(() => _invalid = true);
      return;
    }
    FocusScope.of(context).unfocus();
    // Input validation is not OTP verification. Never accept a local/demo code.
    await showInfoDialog(
      context,
      titleKey: 'otp_title',
      messageKey: 'otp_verification_pending',
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OtpCodeField(
        controller: _code,
        errorText: _invalid ? 'otp_invalid'.tr(context: context) : null,
        onChanged: (_) {
          if (_invalid) setState(() => _invalid = false);
        },
        onSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: 16),
      DefaultButton.compact(
        text: 'otp_done'.tr(context: context),
        onPressed: _submit,
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'otp_no_code'.tr(context: context),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          TextButton(
            onPressed: () => showInfoDialog(
              context,
              titleKey: 'otp_resend',
              messageKey: 'otp_delivery_pending',
            ),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
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
      ),
    ],
  );
}
