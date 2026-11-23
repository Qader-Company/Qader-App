import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/maybe_read.dart';
import '../../../../../core/helpers/feature_dialog.dart';
import '../../../../../core/resources/qader_design.dart';
import '../../../../../core/widgets/default_button.dart';
import '../../../../../core/widgets/qader_asset.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/router/route_args.dart';
import '../../../domain/repositories/google_sign_in_client.dart';
import '../../cubit/auth_session_cubit.dart';
import '../../cubit/google_sign_in_cubit.dart';

/// Outlined provider button (Google/Apple) used under the auth forms.
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.provider,
    required this.labelKey,
    required this.onPressed,
    this.isLoading = false,
  });
  final String provider;
  final String labelKey;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => DefaultButton.compact(
    isOutlined: true,
    color: QaderDesign.border,
    isLoading: isLoading,
    onPressed: onPressed,
    child: Semantics(
      label: labelKey.tr(context: context),
      child: QaderAsset(provider, width: 20, height: 20),
    ),
  );
}

/// Opens Google's account picker, then signs in with the picked account
/// (`AuthSessionCubit.googleLogin`) and continues like the email login.
/// Without a [GoogleSignInClient] (tests, previews) it falls back to the
/// "not connected yet" dialog.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});
  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  /// This button started the session request, so it reports the result
  /// (the email form reports its own).
  bool _signingIn = false;

  @override
  Widget build(BuildContext context) {
    final client = context.maybeRead<GoogleSignInClient>();
    final session = context.maybeRead<AuthSessionCubit>();
    if (client == null || session == null) {
      return SocialButton(
        provider: 'google',
        labelKey: 'google_sign_in',
        onPressed: () => showPendingFeature(context, 'google_sign_in'),
      );
    }
    return BlocProvider(
      create: (_) => GoogleSignInCubit(client),
      child: BlocListener<AuthSessionCubit, AuthSessionState>(
        bloc: session,
        listener: _onSession,
        child: BlocConsumer<GoogleSignInCubit, GoogleSignInState>(
          listener: (context, state) => _onPicked(context, state, session),
          builder: (context, state) =>
              BlocBuilder<AuthSessionCubit, AuthSessionState>(
                bloc: session,
                buildWhen: (a, b) => a.status != b.status,
                builder: (context, sessionState) => SocialButton(
                  provider: 'google',
                  labelKey: 'google_sign_in',
                  isLoading:
                      state.loading ||
                      (_signingIn && sessionState.status == AuthStatus.loading),
                  onPressed: context.read<GoogleSignInCubit>().signIn,
                ),
              ),
        ),
      ),
    );
  }

  void _onPicked(
    BuildContext context,
    GoogleSignInState state,
    AuthSessionCubit session,
  ) {
    if (state.failure case final failure?) {
      _show(context, failure.message);
    } else if (state.account case final account?) {
      setState(() => _signingIn = true);
      session.googleLogin(account.idToken, name: account.name);
    }
  }

  void _onSession(BuildContext context, AuthSessionState state) {
    if (!_signingIn || state.status == AuthStatus.loading) return;
    setState(() => _signingIn = false);
    if (state.status == AuthStatus.authenticated) {
      final user = state.user!;
      context.go(
        AppRouter.profileSetup,
        extra: ProfileSetupSeed(name: user.fullName, email: user.email),
      );
    } else if (state.failure case final failure?) {
      _show(context, failure.message);
    }
  }

  void _show(BuildContext context, String message) {
    showAppToast(
      context,
      message.startsWith('auth_') || message.startsWith('google_')
          ? message.tr(context: context)
          : message,
      type: ToastType.error,
    );
  }
}
