import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/env/app_env.dart';
import '../../features/home/presentation/view/home_view.dart';
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

abstract class AppRouter {
  static const root = '/';
  static const onboarding = '/onboarding';
  static const chooseRole = '/choose-role';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const home = '/home';
  static const forgotPassword = '/forgot-password';
  static const otp = '/otp';
  static const profileSetup = '/profile-setup';
  static const talentProfile = '/talent-profile';
  static const profileReview = '/profile-review';
  static const profileReport = '/profile-report';
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: root,
    observers: [routeObserver],
    debugLogDiagnostics: !AppEnv.instance.isProd,
    routes: [
      GoRoute(path: root, builder: (context, state) => const SplashView()),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(
        path: chooseRole,
        builder: (context, state) => const ChooseRoleView(),
      ),
      GoRoute(
        path: signIn,
        builder: (context, state) => SignInView(
          role: state.uri.queryParameters['role'] == 'client'
              ? AccountRole.client
              : AccountRole.talent,
        ),
      ),
      GoRoute(
        path: signUp,
        builder: (context, state) => SignUpView(
          role: state.uri.queryParameters['role'] == 'client'
              ? AccountRole.client
              : AccountRole.talent,
        ),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => ForgotPasswordView(
          role: state.uri.queryParameters['role'] == 'client'
              ? AccountRole.client
              : AccountRole.talent,
        ),
      ),
      GoRoute(
        path: otp,
        redirect: (context, state) => state.extra is PasswordRecoveryRequest
            ? null
            : Uri(
                path: forgotPassword,
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
        path: profileSetup,
        builder: (context, state) => ProfileSetupView(
          seed: state.extra is ProfileSetupSeed
              ? state.extra as ProfileSetupSeed
              : null,
        ),
      ),
      GoRoute(
        path: talentProfile,
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
        path: profileReview,
        builder: (context, state) => const ProfileReviewView(),
      ),
      GoRoute(
        path: profileReport,
        builder: (context, state) => const ProfileEvaluationView(),
      ),
      GoRoute(path: home, builder: (context, state) => const HomeView()),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text('page_not_found'.tr(context: context))),
      body: Center(
        child: TextButton(
          onPressed: () => context.go(root),
          child: Text('go_home'.tr(context: context)),
        ),
      ),
    ),
  );
}
