import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
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
    sl<AuthRepository>(),
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
    child: BlocBuilder<EmailVerificationCubit, EmailVerificationState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state.status == EmailVerificationStatus.success) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('auth_email_verified'.tr()),
              const SizedBox(height: 16),
              DefaultButton.compact(
                text: 'sign_in'.tr(),
                onPressed: () => context.go('/sign-in?role=talent'),
              ),
            ],
          );
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
