import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// Route paths shared by every feature, plus the app's [GoRouter].
///
/// The routes themselves are built in `lib/app/router/app_routes.dart` and
/// registered with [configure] at startup, so this file stays feature-free.
abstract class AppRouter {
  static const root = '/';
  static const onboarding = '/onboarding';
  static const chooseRole = '/choose-role';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const home = '/home';
  static const statusPreview = '/status-preview';
  static const account = '/account';
  static const forgotPassword = '/forgot-password';
  static const otp = '/otp';
  static const verifyEmail = '/verify-email';
  static const profileSetup = '/profile-setup';
  static const talentProfile = '/talent-profile';
  static const profileReview = '/profile-review';
  static const profileReport = '/profile-report';
  static GoRouter Function()? _build;
  static GoRouter? _router;

  static void configure(GoRouter Function() build) {
    _build = build;
    _router = null;
  }

  static GoRouter get router {
    final build = _build;
    if (build == null) {
      throw StateError(
        'AppRouter.configure was not called (initServiceLocator).',
      );
    }
    return _router ??= build();
  }
}
