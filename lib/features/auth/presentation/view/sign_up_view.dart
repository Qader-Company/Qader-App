import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/helpers/validators.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/default_form_field.dart';
import '../../../../core/widgets/qader_design.dart';
import 'choose_role_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key, this.role = AccountRole.talent});
  final AccountRole role;

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirmation = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // No account or authentication token is created until the API is connected.
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('register_title'.tr(context: context)),
        content: Text('register_pending'.tr(context: context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('confirm'.tr(context: context)),
          ),
        ],
      ),
    );
  }

  void _signIn() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('${AppRouter.signIn}?role=${widget.role.name}');
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeading(title: 'register_title', subtitle: 'register_hint'),
          const SizedBox(height: 16),
          _RegistrationField(
            controller: _name,
            label: 'full_name',
            hint: 'full_name_hint',
            icon: const QaderAsset('user', width: 12.9, height: 16.25),
            keyboardType: TextInputType.name,
            validator: Validators.required,
          ),
          const SizedBox(height: 12),
          _RegistrationField(
            controller: _email,
            label: 'email',
            hint: 'email_hint',
            icon: const QaderAsset('mail', width: 17.9, height: 15.4),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => Validators.email(value?.trim()),
          ),
          const SizedBox(height: 12),
          _RegistrationField(
            controller: _password,
            label: 'password',
            hint: 'password_hint',
            icon: const QaderAsset('lock', width: 14.6, height: 18),
            obscure: _hidePassword,
            validator: (value) =>
                Validators.required(value) ?? Validators.minLength(value, 8),
            suffix: _PasswordVisibility(
              hidden: _hidePassword,
              field: 'password',
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
          const SizedBox(height: 12),
          _RegistrationField(
            controller: _confirmation,
            label: 'confirm_password',
            hint: 'password_hint',
            icon: const QaderAsset('lock', width: 14.6, height: 18),
            obscure: _hideConfirmation,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (value) =>
                Validators.required(value) ??
                Validators.confirmPassword(value, _password.text),
            suffix: _PasswordVisibility(
              hidden: _hideConfirmation,
              field: 'confirm_password',
              onPressed: () =>
                  setState(() => _hideConfirmation = !_hideConfirmation),
            ),
          ),
          const SizedBox(height: 12),
          DefaultButton(
            text: 'sign_up'.tr(context: context),
            onPressed: _submit,
            height: 40,
            radius: 8,
            color: QaderDesign.primary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 15,
            child: Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE5E5E5))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'or'.tr(context: context),
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFE5E5E5))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'sign_in_with'.tr(context: context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF737373),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final provider in ['google', 'apple']) ...[
                if (provider == 'apple') const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: QaderDesign.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => showPendingFeature(
                        context,
                        provider == 'google'
                            ? 'google_sign_in'
                            : 'apple_sign_in',
                      ),
                      child: Semantics(
                        label:
                            (provider == 'google'
                                    ? 'google_sign_in'
                                    : 'apple_sign_in')
                                .tr(context: context),
                        child: QaderAsset(provider, width: 20, height: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'already_have_account'.tr(context: context),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: _signIn,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'sign_in_link'.tr(context: context),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: QaderDesign.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _RegistrationField extends StatelessWidget {
  const _RegistrationField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final Widget icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => DefaultFormField(
    controller: controller,
    label: label.tr(context: context),
    hint: hint.tr(context: context),
    labelSpacing: 6,
    labelStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
      color: Color(0xFF404040),
    ),
    textStyle: const TextStyle(fontSize: 14, height: 20 / 14),
    prefixIcon: Center(widthFactor: 1, heightFactor: 1, child: icon),
    suffixIcon: suffix,
    obscure: obscure,
    keyboardType: keyboardType,
    validator: validator,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
  );
}

class _PasswordVisibility extends StatelessWidget {
  const _PasswordVisibility({
    required this.hidden,
    required this.field,
    required this.onPressed,
  });
  final bool hidden;
  final String field;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    style: IconButton.styleFrom(
      minimumSize: const Size(40, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    padding: const EdgeInsets.all(8),
    tooltip:
        '${(hidden ? 'show_password' : 'hide_password').tr(context: context)}: ${field.tr(context: context)}',
    onPressed: onPressed,
    icon: hidden
        ? const QaderAsset('view_off', width: 16, height: 16)
        : const Icon(Icons.visibility_outlined, size: 18),
  );
}
