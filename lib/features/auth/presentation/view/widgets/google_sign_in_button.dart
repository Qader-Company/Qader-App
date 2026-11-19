import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/maybe_read.dart';
import '../../../../../core/helpers/feature_dialog.dart';
import '../../../../../core/resources/qader_design.dart';
import '../../../../../core/widgets/default_button.dart';
import '../../../../../core/widgets/qader_asset.dart';
import '../../../domain/repositories/google_sign_in_client.dart';
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

/// Opens Google's account picker. Without a [GoogleSignInClient] (tests,
/// previews) it falls back to the "not connected yet" dialog.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    final client = context.maybeRead<GoogleSignInClient>();
    if (client == null) {
      return SocialButton(
        provider: 'google',
        labelKey: 'google_sign_in',
        onPressed: () => showPendingFeature(context, 'google_sign_in'),
      );
    }
    return BlocProvider(
      create: (_) => GoogleSignInCubit(client),
      child: BlocConsumer<GoogleSignInCubit, GoogleSignInState>(
        listener: _onResult,
        builder: (context, state) => SocialButton(
          provider: 'google',
          labelKey: 'google_sign_in',
          isLoading: state.loading,
          onPressed: context.read<GoogleSignInCubit>().signIn,
        ),
      ),
    );
  }

  void _onResult(BuildContext context, GoogleSignInState state) {
    if (state.failure != null) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(state.failure!.message.tr(context: context))),
        );
    } else if (state.account != null) {
      // The backend social login is not wired yet (see GoogleSignInCubit).
      showPendingFeature(context, 'google_sign_in');
    }
  }
}
