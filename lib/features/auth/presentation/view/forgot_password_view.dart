import 'package:flutter/material.dart';
import '../../domain/entities/account_role.dart';
import 'widgets/auth_layout.dart';
import 'widgets/password_recovery_form.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key, this.role = AccountRole.talent});
  final AccountRole role;

  @override
  Widget build(BuildContext context) =>
      AuthLayout(child: PasswordRecoveryForm(role: role));
}
