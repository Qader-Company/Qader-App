import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/env/app_env.dart';
import '../../features/home/presentation/view/home_view.dart';
import '../../features/auth/presentation/view/splash_view.dart';
import '../../features/auth/presentation/view/choose_role_view.dart';
import '../../features/auth/presentation/view/sign_in_view.dart';
import '../../features/auth/presentation/view/sign_up_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

abstract class AppRouter {
  static const root = '/';
  static const chooseRole = '/choose-role';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const home = '/home';
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: root,
    observers: [routeObserver],
    debugLogDiagnostics: !AppEnv.instance.isProd,
    routes: [
      GoRoute(path: root, builder: (context, state) => const SplashView()),
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
