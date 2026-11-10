import 'package:easy_localization/easy_localization.dart';
import '../../features/auth/domain/entities/email_verification_challenge.dart';
import '../../features/auth/presentation/view/email_verification_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../env/app_env.dart';
import '../../core/di/service_locator.dart';
import '../../core/storage/app_preferences.dart';
import '../../features/auth/presentation/view/account_view.dart';
import '../../features/home/presentation/view/home_view.dart';
import '../../features/home/presentation/view/application_status_view.dart';
import '../../features/home/presentation/status_copy.dart';
import '../../features/auth/presentation/view/splash_view.dart';
import '../../features/auth/presentation/view/choose_role_view.dart';
import '../../features/auth/domain/entities/account_role.dart';
import '../../features/auth/presentation/view/sign_in_view.dart';
import '../../features/auth/presentation/view/sign_up_view.dart';
import '../../features/auth/presentation/view/forgot_password_view.dart';
import '../../features/auth/presentation/view/otp_view.dart';
import '../../features/onboarding/presentation/view/onboarding_view.dart';
import '../../features/auth/domain/entities/password_recovery_request.dart';

import '../../features/profile_setup/presentation/view/profile_setup_view.dart';
import '../../features/profile_setup/presentation/profile_setup_controller.dart';

import '../../features/talent_profile/presentation/view/talent_profile_view.dart';
import '../../features/talent_profile/presentation/view/profile_review_view.dart';

import '../../features/talent_profile/presentation/view/profile_evaluation_view.dart';
import '../../features/talent_profile/domain/talent_profile.dart';
import '../../core/router/app_router.dart';
export '../../core/router/app_router.dart';

/// Every route of the app. Registered through [AppRouter.configure] by the
/// composition root, so `core` never imports a feature.
GoRouter buildAppRouter() => GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: AppRouter.root,
  refreshListenable: sl<AppPreferences>().sessionRevision,
  redirect: (context, state) {
    if (state.uri.path == AppRouter.account &&
        !sl<AppPreferences>().isLoggedIn) {
      return '${AppRouter.signIn}?role=talent';
    }
    return null;
  },
  observers: [routeObserver],
  debugLogDiagnostics: !AppEnv.instance.isProd,
  routes: [
    GoRoute(
      path: AppRouter.statusPreview,
      builder: (context, state) => ApplicationStatusView(
        initialStatus: ApplicationStatus.values.firstWhere(
          (value) => value.name == state.uri.queryParameters['status'],
          orElse: () => ApplicationStatus.slots,
        ),
      ),
    ),
    GoRoute(
      path: AppRouter.verifyEmail,
      redirect: (context, state) => state.extra is EmailVerificationChallenge
          ? null
          : '/sign-in?role=talent',
      builder: (context, state) => EmailVerificationView(
        challenge: state.extra! as EmailVerificationChallenge,
      ),
    ),
    GoRoute(
      path: AppRouter.account,
      builder: (context, state) => const AccountView(),
    ),
    GoRoute(
      path: AppRouter.root,
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: AppRouter.onboarding,
      builder: (context, state) => const OnboardingView(),
    ),
    GoRoute(
      path: AppRouter.chooseRole,
      builder: (context, state) => const ChooseRoleView(),
    ),
    GoRoute(
      path: AppRouter.signIn,
      builder: (context, state) => SignInView(
        role: state.uri.queryParameters['role'] == 'client'
            ? AccountRole.client
            : AccountRole.talent,
      ),
    ),
    GoRoute(
      path: AppRouter.signUp,
      builder: (context, state) => SignUpView(
        role: state.uri.queryParameters['role'] == 'client'
            ? AccountRole.client
            : AccountRole.talent,
      ),
    ),
    GoRoute(
      path: AppRouter.forgotPassword,
      builder: (context, state) => ForgotPasswordView(
        role: state.uri.queryParameters['role'] == 'client'
            ? AccountRole.client
            : AccountRole.talent,
      ),
    ),
    GoRoute(
      path: AppRouter.otp,
      redirect: (context, state) => state.extra is PasswordRecoveryRequest
          ? null
          : Uri(
              path: AppRouter.forgotPassword,
              queryParameters: {
                'role': state.uri.queryParameters['role'] == 'client'
                    ? 'client'
                    : 'talent',
              },
            ).toString(),
      builder: (context, state) =>
          OtpView(request: state.extra! as PasswordRecoveryRequest),
    ),
    GoRoute(
      path: AppRouter.profileSetup,
      builder: (context, state) => ProfileSetupView(
        seed: state.extra is ProfileSetupSeed
            ? state.extra as ProfileSetupSeed
            : null,
      ),
    ),
    GoRoute(
      path: AppRouter.talentProfile,
      builder: (context, state) {
        final status = switch (state.uri.queryParameters['status']) {
          'rejected' => TalentProfileStatus.rejected,
          'restricted' => TalentProfileStatus.restricted,
          _ => TalentProfileStatus.accepted,
        };
        return TalentProfileView(
          profile: TalentProfile(
            status: status,
            reviewAvailableAt: status == TalentProfileStatus.accepted
                ? null
                : DateTime.now().add(
                    const Duration(days: 72, hours: 21, minutes: 1),
                  ),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRouter.profileReview,
      builder: (context, state) => const ProfileReviewView(),
    ),
    GoRoute(
      path: AppRouter.profileReport,
      builder: (context, state) => const ProfileEvaluationView(),
    ),
    GoRoute(
      path: AppRouter.home,
      builder: (context, state) => HomeView(
        preview:
            !sl<AppPreferences>().isLoggedIn ||
            state.uri.queryParameters['preview'] == 'true',
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: Text('page_not_found'.tr(context: context))),
    body: Center(
      child: TextButton(
        onPressed: () => context.go(AppRouter.root),
        child: Text('go_home'.tr(context: context)),
      ),
    ),
  ),
);
