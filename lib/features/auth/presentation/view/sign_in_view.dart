import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/account_role.dart';
import 'widgets/auth_layout.dart';
import 'widgets/auth_heading.dart';
import 'widgets/auth_footer.dart';
import 'widgets/sign_in_form.dart';

class SignInView extends StatelessWidget {
  const SignInView({super.key, this.role = AccountRole.talent});
  final AccountRole role;
  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(title: 'sign_in', subtitle: 'sign_in_hint'),
        const SizedBox(height: 16),
        SignInForm(role: role),
        const SizedBox(height: 16),
        AuthFooter(
          onAction: () => context.push('${AppRouter.signUp}?role=${role.name}'),
        ),
      ],
    ),
  );
}
