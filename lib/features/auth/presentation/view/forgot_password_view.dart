import 'package:flutter/material.dart';
import '../../domain/entities/account_role.dart';
import 'widgets/auth_heading.dart';
import 'widgets/auth_layout.dart';
import 'widgets/forgot_password_form.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key, this.role = AccountRole.talent});
  final AccountRole role;

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(
          title: 'forgot_password_title',
          subtitle: 'forgot_password_hint',
        ),
        const SizedBox(height: 16),
        ForgotPasswordForm(role: role),
      ],
    ),
  );
}
