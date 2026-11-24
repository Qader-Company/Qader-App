import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/env/app_env.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/qader_design.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Where the splash goes: a signed-in talent resumes profile setup (which
/// moves on by itself once the profile is done), a returning visitor picks
/// a role, and a first visit starts the intro.
String splashDestination(AppPreferences preferences) => preferences.isLoggedIn
    ? AppRouter.profileSetup
    : preferences.isOnBoardingViewed()
    ? AppRouter.chooseRole
    : AppRouter.onboarding;

class SplashView extends StatefulWidget {
  const SplashView({super.key});
  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(AppEnv.instance.splashDuration, () {
      if (!mounted) return;
      context.go(splashDestination(context.read<AppPreferences>()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: QaderLogo(large: true)));
}
