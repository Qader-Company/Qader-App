import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../cubit/auth_session_cubit.dart';
import 'widgets/auth_layout.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../profile_setup/presentation/profile_setup_controller.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});
  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  late final _session = sl<AuthSessionCubit>();
  @override
  void initState() {
    super.initState();
    if (_session.state.status != AuthStatus.authenticated) {
      _session.restore();
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: BlocBuilder<AuthSessionCubit, AuthSessionState>(
      bloc: _session,
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'auth_my_account'.tr(context: context),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          if (state.status == AuthStatus.loading)
            const Center(child: CircularProgressIndicator()),
          if (state.user case final user?) ...[
            Text(user.fullName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(user.email),
            const SizedBox(height: 16),
            DefaultButton.compact(
              text: 'auth_complete_profile'.tr(context: context),
              onPressed: state.status == AuthStatus.loading
                  ? null
                  : () => context.push(
                      AppRouter.profileSetup,
                      extra: ProfileSetupSeed(
                        name: user.fullName,
                        email: user.email,
                      ),
                    ),
            ),
          ],
          if (state.failure case final failure?) ...[
            Text(
              failure.message.startsWith('auth_')
                  ? failure.message.tr(context: context)
                  : failure.message,
            ),
            const SizedBox(height: 16),
            DefaultButton.compact(
              text: 'auth_retry'.tr(context: context),
              onPressed: _session.restore,
            ),
          ],
          const SizedBox(height: 24),
          DefaultButton.compact(
            text: 'auth_sign_out'.tr(context: context),
            onPressed: state.status == AuthStatus.loading
                ? null
                : _session.logout,
          ),
          const LanguageToggleButton(),
        ],
      ),
    ),
  );
}
