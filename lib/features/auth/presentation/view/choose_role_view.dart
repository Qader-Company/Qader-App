import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/qader_design.dart';

enum AccountRole { talent, client }

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
        const AuthHeading(title: 'choose_role', subtitle: 'choose_role_hint'),
        const SizedBox(height: 16),
        for (final role in AccountRole.values) ...[
          _RoleCard(
            role: role,
            selected: _role == role,
            onTap: () => setState(() => _role = role),
          ),
          if (role == AccountRole.talent) const SizedBox(height: 16),
        ],
        const SizedBox(height: 32),
        DefaultButton(
          text: 'continue_as'.tr(
            context: context,
            args: [_role.name.tr(context: context)],
          ),
          height: 40,
          radius: 8,
          fontSize: 14,
          color: QaderDesign.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          onPressed: () =>
              context.push('${AppRouter.signIn}?role=${_role.name}'),
        ),
      ],
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });
  final AccountRole role;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? QaderDesign.paleBlue : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? QaderDesign.primary : QaderDesign.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 156),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EFFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: QaderAsset(
                          role.name,
                          width: role == AccountRole.talent ? 15.5 : 13.5,
                          height: role == AccountRole.talent ? 19.5 : 21.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        role.name.tr(context: context),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected)
                      const QaderAsset('radio_selected', width: 20, height: 20)
                    else
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: QaderDesign.border),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${role.name}_description'.tr(context: context),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    color: QaderDesign.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
