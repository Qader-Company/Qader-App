import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/helpers/feature_dialog.dart';
import '../../../../../core/helpers/validators.dart';
import '../../../../../core/widgets/default_button.dart';
import '../../../../../core/widgets/qader_asset.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../domain/entities/account_role.dart';
import '../../../../profile_setup/presentation/profile_setup_controller.dart';
import 'auth_form_field.dart';
import 'auth_password_field.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key, this.role = AccountRole.talent});
  final AccountRole role;
  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
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
    // No account/session is created until the registration API is connected.
    if (widget.role == AccountRole.client) {
      await showInfoDialog(
        context,
        titleKey: 'register_title',
        messageKey: 'register_pending',
      );
      return;
    }
    final preview = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('register_title'.tr(context: context)),
        content: Text('register_pending'.tr(context: context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('confirm'.tr(context: context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('profile_preview_talent_profile'.tr(context: context)),
          ),
        ],
      ),
    );
    if (preview == true && mounted) {
      context.push(
        AppRouter.profileSetup,
        extra: ProfileSetupSeed(
          name: _name.text.trim(),
          email: _email.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFormField(
          controller: _name,
          labelKey: 'full_name',
          hintKey: 'full_name_hint',
          icon: const QaderAsset('user', width: 12.9, height: 16.25),
          keyboardType: TextInputType.name,
          validator: Validators.required,
        ),
        const SizedBox(height: 12),
        AuthFormField(
          controller: _email,
          labelKey: 'email',
          hintKey: 'email_hint',
          icon: const QaderAsset('mail', width: 17.9, height: 15.4),
          keyboardType: TextInputType.emailAddress,
          validator: (value) => Validators.email(value?.trim()),
        ),
        const SizedBox(height: 12),
        AuthPasswordField(
          controller: _password,
          labelInTooltip: true,
          validator: (value) =>
              Validators.required(value) ?? Validators.minLength(value, 8),
        ),
        const SizedBox(height: 12),
        AuthPasswordField(
          controller: _confirmation,
          labelKey: 'confirm_password',
          labelInTooltip: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          validator: (value) =>
              Validators.required(value) ??
              Validators.confirmPassword(value, _password.text),
        ),
        const SizedBox(height: 12),
        DefaultButton.compact(
          text: 'sign_up'.tr(context: context),
          onPressed: _submit,
        ),
      ],
    ),
  );
}
