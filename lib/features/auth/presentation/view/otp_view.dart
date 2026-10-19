import 'package:flutter/material.dart';
import '../../domain/entities/password_recovery_request.dart';
import 'widgets/auth_heading.dart';
import 'widgets/auth_layout.dart';
import 'widgets/otp_verification_form.dart';

class OtpView extends StatelessWidget {
  const OtpView({super.key, required this.request});
  final PasswordRecoveryRequest request;

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(title: 'otp_title', subtitle: 'otp_hint'),
        const SizedBox(height: 16),
        OtpVerificationForm(request: request),
      ],
    ),
  );
}
