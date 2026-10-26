import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/helpers/validators.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/widgets/default_button.dart';
import '../../../../../core/widgets/qader_asset.dart';
import '../../../domain/entities/registration_request.dart';
import '../../cubit/registration_cubit.dart';
import 'auth_form_field.dart';
import 'auth_password_field.dart';

class TalentSignUpForm extends StatefulWidget {
  const TalentSignUpForm({super.key});
  @override
  State<TalentSignUpForm> createState() => _TalentSignUpFormState();
}

class _TalentSignUpFormState extends State<TalentSignUpForm> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  late final _cubit = sl<RegistrationCubit>();

  String? _nameValidator(String? value) {
    final required = Validators.required(value?.trim());
    if (required != null) return required;
    return value!.trim().length > 100 ? 'auth_name_too_long'.tr() : null;
  }

  void _submit() {
    if (_cubit.state.status == RegistrationStatus.loading ||
        !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    _cubit.submit(
      RegistrationRequest(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirmation.text,
      ),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<RegistrationCubit, RegistrationState>(
    bloc: _cubit,
    listener: (context, state) {
      if (state.status == RegistrationStatus.success) {
        _password.clear();
        _confirmation.clear();
        context.go(AppRouter.verifyEmail, extra: state.challenge);
      }
    },
    builder: (context, state) {
      if (state.status == RegistrationStatus.success) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('auth_registration_success'.tr(context: context)),
            const SizedBox(height: 16),
            DefaultButton.compact(
              text: 'otp_title'.tr(context: context),
              onPressed: () =>
                  context.go(AppRouter.verifyEmail, extra: state.challenge),
            ),
          ],
        );
      }
      return Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFormField(
              controller: _firstName,
              labelKey: 'auth_first_name',
              hintKey: 'auth_first_name',
              keyboardType: TextInputType.name,
              icon: const QaderAsset('user', width: 12.9, height: 16.25),
              validator: _nameValidator,
            ),
            const SizedBox(height: 12),
            AuthFormField(
              controller: _lastName,
              labelKey: 'auth_last_name',
              hintKey: 'auth_last_name',
              keyboardType: TextInputType.name,
              icon: const QaderAsset('user', width: 12.9, height: 16.25),
              validator: _nameValidator,
            ),
            const SizedBox(height: 12),
            AuthFormField(
              controller: _email,
              labelKey: 'email',
              hintKey: 'email_hint',
              keyboardType: TextInputType.emailAddress,
              icon: const QaderAsset('mail', width: 17.9, height: 15.4),
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
            if (state.failure case final failure?) ...[
              const SizedBox(height: 12),
              Text(
                failure.message.startsWith('auth_')
                    ? failure.message.tr(context: context)
                    : failure.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            DefaultButton.compact(
              text: 'sign_up'.tr(context: context),
              isLoading: state.status == RegistrationStatus.loading,
              onPressed: _submit,
            ),
          ],
        ),
      );
    },
  );
}
