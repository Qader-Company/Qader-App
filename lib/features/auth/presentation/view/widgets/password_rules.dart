import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The new-password rules listed under the client's reset form (Figma).
class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key});

  static const _style = TextStyle(fontSize: 12, height: 1.5);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final key in const [
        'auth_password_rules_title',
        'auth_password_rule_length',
        'auth_password_rule_match',
      ]) ...[
        const SizedBox(height: 8),
        Text(key.tr(context: context), style: _style),
      ],
    ],
  );
}
