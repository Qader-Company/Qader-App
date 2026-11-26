import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/helpers/validators.dart';
import '../../../../../core/widgets/default_button.dart';
import '../../../../../core/widgets/qader_asset.dart';
import '../../../data/repositories/password_recovery_repository.dart';
import '../../../domain/entities/account_role.dart';
import '../../cubit/password_recovery_cubit.dart';
import 'auth_form_field.dart';
import 'auth_heading.dart';
import 'auth_password_field.dart';
import 'otp_code_field.dart';
import 'otp_resend_link.dart';
import 'password_rules.dart';

/// Email, code and new password, in one screen, for either role.
class PasswordRecoveryForm extends StatefulWidget {
  const PasswordRecoveryForm({super.key, this.role = AccountRole.talent});
  final AccountRole role;
  @override
  State<PasswordRecoveryForm> createState() => _PasswordRecoveryFormState();
}

class _PasswordRecoveryFormState extends State<PasswordRecoveryForm> {
  final _emailForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  late final _cubit = PasswordRecoveryCubit(
    context.read<PasswordRecoveryRepository>(),
    role: widget.role,
  );

  @override
  void dispose() {
    _cubit.close();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (_cubit.state.loading) return;
    FocusScope.of(context).unfocus();
    switch (_cubit.state.step) {
      case PasswordRecoveryStep.email:
        if (_emailForm.currentState!.validate()) {
          _cubit.send(_email.text.trim());
        }
      case PasswordRecoveryStep.code:
        _cubit.verify(_code.text);
      case PasswordRecoveryStep.password:
        if (_passwordForm.currentState!.validate()) {
          _cubit.reset(_password.text, _confirmation.text);
        }
      case PasswordRecoveryStep.done:
        context.go('/sign-in?role=${widget.role.name}');
    }
  }

  /// Clients follow their own Figma frames: different copy, a resend link
  /// and the password rules.
  bool get _client => widget.role == AccountRole.client;

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<PasswordRecoveryCubit, PasswordRecoveryState>(
    bloc: _cubit,
    listener: (context, state) {
      if (state.step == PasswordRecoveryStep.password) _code.clear();
      if (state.step == PasswordRecoveryStep.done) {
        _password.clear();
        _confirmation.clear();
      }
    },
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(
          title: switch (state.step) {
            PasswordRecoveryStep.email => 'forgot_password_title',
            PasswordRecoveryStep.code => 'otp_title',
            PasswordRecoveryStep.password =>
              _client ? 'auth_reset_password_title' : 'auth_new_password_title',
            PasswordRecoveryStep.done => 'auth_reset_success_title',
          },
          subtitle: switch (state.step) {
            PasswordRecoveryStep.email => 'forgot_password_hint',
            PasswordRecoveryStep.code =>
              _client ? 'otp_hint' : 'auth_verify_email_hint',
            PasswordRecoveryStep.password =>
              _client ? 'auth_reset_password_hint' : 'auth_new_password_hint',
            PasswordRecoveryStep.done => 'auth_reset_success_hint',
          },
        ),
        const SizedBox(height: 16),
        if (state.step == PasswordRecoveryStep.email)
          Form(
            key: _emailForm,
            child: AuthFormField(
              controller: _email,
              labelKey: 'email',
              hintKey: 'email_hint',
              icon: const QaderAsset('mail', width: 17.9, height: 15.4),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (value) => Validators.email(value?.trim()),
            ),
          ),
        if (state.step == PasswordRecoveryStep.code) ...[
          if (!_client) ...[
            Text(_cubit.email, textAlign: TextAlign.center),
            const SizedBox(height: 16),
          ],
          OtpCodeField(
            controller: _code,
            codeLength: 6,
            onSubmitted: (_) => _submit(),
          ),
        ],
        if (state.step == PasswordRecoveryStep.password)
          Form(
            key: _passwordForm,
            child: Column(
              children: [
                AuthPasswordField(
                  controller: _password,
                  labelKey: _client ? 'password' : 'auth_new_password_title',
                  validator: (value) =>
                      Validators.required(value) ??
                      Validators.minLength(value, 8),
                ),
                const SizedBox(height: 12),
                AuthPasswordField(
                  controller: _confirmation,
                  labelKey: 'confirm_password',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (value) =>
                      Validators.required(value) ??
                      Validators.confirmPassword(value, _password.text),
                ),
                if (_client)
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: PasswordRules(),
                  ),
              ],
            ),
          ),
        if (state.failure case final failure?) ...[
          const SizedBox(height: 12),
          Text(
            failure.message.startsWith('auth_')
                ? failure.message.tr(context: context)
                : failure.message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        DefaultButton.compact(
          text: switch (state.step) {
            PasswordRecoveryStep.email =>
              (_client ? 'reset_password_action' : 'auth_send_reset_code').tr(
                context: context,
              ),
            PasswordRecoveryStep.code => 'otp_done'.tr(context: context),
            PasswordRecoveryStep.password =>
              (_client ? 'confirm_password' : 'reset_password_action').tr(
                context: context,
              ),
            PasswordRecoveryStep.done => 'sign_in'.tr(context: context),
          },
          isLoading: state.loading && !state.resending,
          onPressed: state.loading ? null : _submit,
        ),
        if (state.step == PasswordRecoveryStep.code) ...[
          const SizedBox(height: 12),
          if (_client)
            OtpResendLink(onPressed: state.loading ? null : _cubit.resend)
          else
            DefaultButton.compact(
              text: 'otp_resend'.tr(context: context),
              isOutlined: true,
              isLoading: state.resending,
              onPressed: state.loading ? null : _cubit.resend,
            ),
          if (state.resent)
            Text(
              'auth_otp_resent'.tr(context: context),
              textAlign: TextAlign.center,
            ),
        ],
      ],
    ),
  );
}
