import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/helpers/validators.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/widgets/default_button.dart';
import '../../../../../core/widgets/qader_asset.dart';
import '../../../domain/entities/account_role.dart';
import 'auth_form_field.dart';
import 'client_sign_in_form.dart';
import 'auth_password_field.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key, required this.role});
  final AccountRole role;
  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Authentication is deliberately not simulated: no session/token is saved.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('preview_title'.tr(context: context)),
        content: Text('preview_hint'.tr(context: context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr(context: context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(
                '${AppRouter.home}?preview=true&role=${widget.role.name}',
              );
            },
            child: Text('preview_home'.tr(context: context)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.role == AccountRole.client
      ? const ClientSignInForm()
      : Form(
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
                validator: (value) => Validators.email(value?.trim()),
              ),
              const SizedBox(height: 12),
              AuthPasswordField(
                controller: _password,
                validator: Validators.required,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(top: 6),
                    minimumSize: const Size(0, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.push(
                    '${AppRouter.forgotPassword}?role=${widget.role.name}',
                  ),
                  child: Text(
                    'forgot_password'.tr(context: context),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              DefaultButton.compact(
                text: 'sign_in'.tr(context: context),
                onPressed: _submit,
              ),
            ],
          ),
        );
}
