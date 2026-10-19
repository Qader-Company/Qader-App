import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/widgets/qader_asset.dart';
import 'auth_form_field.dart';

/// Each field owns its password visibility; form validation stays in the form.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    this.labelKey = 'password',
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.labelInTooltip = false,
  });
  final TextEditingController controller;
  final String labelKey;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool labelInTooltip;
  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _hidden = true;
  @override
  Widget build(BuildContext context) {
    final action = (_hidden ? 'show_password' : 'hide_password').tr(
      context: context,
    );
    return AuthFormField(
      controller: widget.controller,
      labelKey: widget.labelKey,
      hintKey: 'password_hint',
      icon: const QaderAsset('lock', width: 14.6, height: 18),
      obscure: _hidden,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      suffix: IconButton(
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: const EdgeInsets.all(8),
        tooltip: widget.labelInTooltip
            ? '$action: ${widget.labelKey.tr(context: context)}'
            : action,
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: _hidden
            ? const QaderAsset('view_off', width: 16, height: 16)
            : const Icon(Icons.visibility_outlined, size: 18),
      ),
    );
  }
}
