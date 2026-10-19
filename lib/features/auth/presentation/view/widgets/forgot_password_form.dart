import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/helpers/validators.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/widgets/default_button.dart';
import '../../../../../core/widgets/qader_asset.dart';
import '../../../domain/entities/account_role.dart';
import '../../../domain/entities/password_recovery_request.dart';
import 'auth_form_field.dart';

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key, required this.role});
  final AccountRole role;

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final request = PasswordRecoveryRequest(
      email: _email.text.trim(),
      role: widget.role,
    );
    // No request is made to the placeholder backend. Explicitly offer a preview.
    final preview = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('recovery_preview_title'.tr(context: context)),
        content: Text('recovery_preview_hint'.tr(context: context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr(context: context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('preview_otp'.tr(context: context)),
          ),
        ],
      ),
    );
    if (preview != true || !mounted) return;
    context.push('${AppRouter.otp}?role=${widget.role.name}', extra: request);
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFormField(
          controller: _email,
          labelKey: 'email',
          hintKey: 'email_hint',
          icon: const QaderAsset('mail', width: 17.9, height: 15.4),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          validator: (value) => Validators.email(value?.trim()),
        ),
        const SizedBox(height: 12),
        DefaultButton.compact(
          text: 'reset_password_action'.tr(context: context),
          onPressed: _submit,
        ),
      ],
    ),
  );
}
