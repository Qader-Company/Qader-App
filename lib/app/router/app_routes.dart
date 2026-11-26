import 'package:easy_localization/easy_localization.dart';
import '../../features/auth/domain/entities/email_verification_challenge.dart';
import '../../features/auth/presentation/view/email_verification_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/env/app_env.dart';
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
import '../../features/onboarding/presentation/view/onboarding_view.dart';

import '../../features/profile_setup/presentation/view/profile_setup_view.dart';
import '../../features/profile_setup/presentation/cubit/profile_setup_cubit.dart';

import '../../features/talent_profile/presentation/view/talent_profile_view.dart';
import '../../features/talent_profile/presentation/view/profile_review_view.dart';

import '../../features/talent_profile/presentation/view/profile_evaluation_view.dart';
import '../../features/talent_profile/domain/entities/talent_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/offers/domain/repositories/offers_repository.dart';
import '../../features/offers/presentation/preview/offers_preview_data.dart';
import '../../features/offers/presentation/preview/preview_offers_repository.dart';
import '../../features/offers/presentation/view/live_offer_details_view.dart';
import '../../features/offers/presentation/view/preview_offer_details_view.dart';
import '../../features/offers/presentation/view/offers_view.dart';
import '../../features/notifications/presentation/view/notifications_view.dart';
import '../../features/talent_profile/presentation/preview/talent_profile_preview.dart';
import '../../core/router/app_router.dart';
export '../../core/router/app_router.dart';

/// Routes whose screens call talent endpoints.
const _talentOnly = [
  AppRouter.home,
  AppRouter.statusPreview,
  AppRouter.profileSetup,
  AppRouter.profileEdit,
  AppRouter.talentProfile,
  AppRouter.profileReview,
  AppRouter.profileReport,
  AppRouter.offers,
  AppRouter.notifications,
];

/// Every route of the app. Registered through [AppRouter.configure] by the
/// composition root, so `core` never imports a feature.
GoRouter buildAppRouter() => GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: AppRouter.root,
  refreshListenable: sl<AppPreferences>().sessionRevision,
  redirect: (context, state) {
    final preferences = sl<AppPreferences>();
    if (state.uri.path == AppRouter.account && !preferences.isLoggedIn) {
      return '${AppRouter.signIn}?role=talent';
    }
    // Talent screens call talent endpoints: a signed-in client stays on
    // the client side.
    if (preferences.isLoggedIn &&
        preferences.getAccountRole() == AccountRole.client.name &&
        _talentOnly.any(
          (path) =>
              state.uri.path == path || state.uri.path.startsWith('$path/'),
        )) {
      return AppRouter.account;
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
      path: AppRouter.profileSetup,
      builder: (context, state) => ProfileSetupView(
        seed: state.extra is ProfileSetupSeed
            ? state.extra as ProfileSetupSeed
            : null,
      ),
    ),
    // Signed-in talents get their offers from the API; logged-out visitors
    // and `?preview=true` (the drawer's design previews) get sample offers.
    GoRoute(
      path: AppRouter.offers,
      builder: (context, state) =>
          sl<AppPreferences>().isLoggedIn &&
              state.uri.queryParameters['preview'] != 'true'
          ? OffersView(repository: context.read<OffersRepository>())
          : OffersView(
              repository: PreviewOffersRepository(OffersPreviewData.offers),
              preview: true,
            ),
      routes: [
        // Signed-in talents get the offer from the API; sample offers
        // (`?preview=true`, or logged out) open the preview screens.
        GoRoute(
          path: ':id',
          redirect: (context, state) {
            final live =
                sl<AppPreferences>().isLoggedIn &&
                state.uri.queryParameters['preview'] != 'true';
            return live ||
                    OffersPreviewData.byId(state.pathParameters['id']!) != null
                ? null
                : AppRouter.offers;
          },
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return sl<AppPreferences>().isLoggedIn &&
                    state.uri.queryParameters['preview'] != 'true'
                ? LiveOfferDetailsView(offerId: id)
                : PreviewOfferDetailsView(offerId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRouter.notifications,
      redirect: (context, state) => sl<AppPreferences>().isLoggedIn
          ? null
          : '${AppRouter.signIn}?role=talent',
      builder: (context, state) => const NotificationsView(),
    ),
    GoRoute(
      path: AppRouter.profileEdit,
      redirect: (context, state) =>
          sl<AppPreferences>().isLoggedIn ? null : AppRouter.talentProfile,
      builder: (context, state) => const ProfileSetupView(edit: true),
    ),
    GoRoute(
      path: AppRouter.talentProfile,
      builder: (context, state) {
        // Sample profile when logged out or for the status preview links.
        final statusParam = state.uri.queryParameters['status'];
        if (sl<AppPreferences>().isLoggedIn && statusParam == null) {
          return const TalentProfileView();
        }
        final status = switch (statusParam) {
          'rejected' => TalentProfileStatus.rejected,
          'restricted' => TalentProfileStatus.restricted,
          _ => TalentProfileStatus.accepted,
        };
        return TalentProfileView(
          preview: previewTalentProfile.copyWith(
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
      // A sample when signed out or opened from a preview profile.
      builder: (context, state) => ProfileEvaluationView(
        preview:
            !sl<AppPreferences>().isLoggedIn ||
            state.uri.queryParameters['preview'] == 'true',
      ),
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
