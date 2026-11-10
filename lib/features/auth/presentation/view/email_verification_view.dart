import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../../domain/entities/email_verification_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/email_verification_cubit.dart';
import 'widgets/auth_layout.dart';
import 'widgets/auth_heading.dart';
import 'widgets/otp_code_field.dart';

class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({super.key, required this.challenge});
  final EmailVerificationChallenge challenge;
  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  final _code = TextEditingController();
  late final _cubit = EmailVerificationCubit(
    context.read<AuthRepository>(),
    widget.challenge,
  );
  @override
  void dispose() {
    _code.dispose();
    _cubit.close();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    _cubit.submit(_code.text);
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: BlocConsumer<EmailVerificationCubit, EmailVerificationState>(
      bloc: _cubit,
      // Verified: go straight to sign in, no intermediate page.
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == EmailVerificationStatus.success,
      listener: (context, state) {
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('auth_email_verified'.tr())));
        context.go('${AppRouter.signIn}?role=talent');
      },
      builder: (context, state) {
        if (state.status == EmailVerificationStatus.success) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeading(
              title: 'otp_title',
              subtitle: 'auth_verify_email_hint',
            ),
            Text(widget.challenge.email, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OtpCodeField(
              controller: _code,
              codeLength: 6,
              onSubmitted: (_) => _submit(),
            ),
            if (state.failure case final failure?) ...[
              const SizedBox(height: 12),
              Text(
                failure.message.startsWith('auth_')
                    ? failure.message.tr()
                    : failure.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            DefaultButton.compact(
              text: 'otp_done'.tr(),
              isLoading: state.status == EmailVerificationStatus.loading,
              onPressed: state.status == EmailVerificationStatus.resending
                  ? null
                  : _submit,
            ),
            const SizedBox(height: 12),
            DefaultButton.compact(
              text: 'otp_resend'.tr(),
              isOutlined: true,
              isLoading: state.status == EmailVerificationStatus.resending,
              onPressed: state.status == EmailVerificationStatus.loading
                  ? null
                  : _cubit.resend,
            ),
            if (state.status == EmailVerificationStatus.resent) ...[
              const SizedBox(height: 12),
              Text('auth_otp_resent'.tr(), textAlign: TextAlign.center),
            ],
          ],
        );
      },
    ),
  );
}
