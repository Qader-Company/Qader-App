import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/widgets/default_form_field.dart';

/// Shared auth labels and icons composed with the existing custom form field.
class AuthFormField extends StatelessWidget {
  const AuthFormField({
    super.key,
    required this.controller,
    required this.labelKey,
    required this.hintKey,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String labelKey;
  final String hintKey;
  final Widget icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  @override
  Widget build(BuildContext context) => DefaultFormField(
    compact: true,
    controller: controller,
    label: labelKey.tr(context: context),
    hint: hintKey.tr(context: context),
    prefixIcon: Center(widthFactor: 1, heightFactor: 1, child: icon),
    suffixIcon: suffix,
    obscure: obscure,
    keyboardType: keyboardType,
    validator: validator,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
  );
}
