import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../../domain/entities/account_role.dart';
import 'widgets/auth_layout.dart';
import 'widgets/auth_heading.dart';
import 'widgets/role_card.dart';

class ChooseRoleView extends StatefulWidget {
  const ChooseRoleView({super.key});
  @override
  State<ChooseRoleView> createState() => _ChooseRoleViewState();
}

class _ChooseRoleViewState extends State<ChooseRoleView> {
  AccountRole _role = AccountRole.talent;
  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(
          title: 'choose_role',
          subtitle: 'choose_role_hint',
          titleHeight: 32 / 24,
        ),
        const SizedBox(height: 16),
        for (final role in AccountRole.values) ...[
          RoleCard(
            role: role,
            selected: _role == role,
            onTap: () => setState(() => _role = role),
          ),
          if (role == AccountRole.talent) const SizedBox(height: 16),
        ],
        const SizedBox(height: 32),
        DefaultButton.compact(
          text: 'continue_as'.tr(
            context: context,
            args: [_role.name.tr(context: context)],
          ),
          onPressed: () =>
              context.push('${AppRouter.signIn}?role=${_role.name}'),
        ),
      ],
    ),
  );
}
