import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/helpers/validators.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/widgets/default_button.dart';
import '../../../../../core/widgets/qader_asset.dart';
import '../../cubit/auth_session_cubit.dart';
import 'auth_form_field.dart';
import 'auth_password_field.dart';
import '../../../../profile_setup/presentation/profile_setup_controller.dart';

class TalentSignInForm extends StatefulWidget {
  const TalentSignInForm({super.key});
  @override
  State<TalentSignInForm> createState() => _TalentSignInFormState();
}

class _TalentSignInFormState extends State<TalentSignInForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final _session = sl<AuthSessionCubit>();
  void _submit() {
    if (_session.state.status == AuthStatus.loading ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    _session.login(_email.text.trim(), _password.text);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<AuthSessionCubit, AuthSessionState>(
    bloc: _session,
    listener: (context, state) {
      if (state.status == AuthStatus.authenticated) {
        context.go(
          AppRouter.profileSetup,
          extra: ProfileSetupSeed(
            name: state.user!.fullName,
            email: state.user!.email,
          ),
        );
      }
    },
    builder: (context, state) => Form(
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
            validator: (value) =>
                Validators.required(value) ?? Validators.minLength(value, 8),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: state.status == AuthStatus.loading
                  ? null
                  : () =>
                        context.push('${AppRouter.forgotPassword}?role=talent'),
              child: Text('forgot_password'.tr(context: context)),
            ),
          ),
          if (state.failure != null) ...[
            Text(
              state.failure!.message.startsWith('auth_')
                  ? state.failure!.message.tr(context: context)
                  : state.failure!.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          DefaultButton.compact(
            text: 'sign_in'.tr(context: context),
            isLoading: state.status == AuthStatus.loading,
            onPressed: _submit,
          ),
        ],
      ),
    ),
  );
}
