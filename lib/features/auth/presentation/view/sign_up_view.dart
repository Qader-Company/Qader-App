import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/account_role.dart';
import 'widgets/auth_layout.dart';
import 'widgets/auth_heading.dart';
import 'widgets/auth_footer.dart';
import 'widgets/sign_up_form.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key, this.role = AccountRole.talent});
  final AccountRole role;
  void _signIn(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('${AppRouter.signIn}?role=${role.name}');
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(title: 'register_title', subtitle: 'register_hint'),
        const SizedBox(height: 16),
        const SignUpForm(),
        const SizedBox(height: 12),
        AuthFooter(registration: true, onAction: () => _signIn(context)),
      ],
    ),
  );
}
