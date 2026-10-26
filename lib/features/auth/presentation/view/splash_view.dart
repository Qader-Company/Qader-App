import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/env/app_env.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/qader_design.dart';

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
      context.go(
        sl<AppPreferences>().isLoggedIn
            ? AppRouter.account
            : sl<AppPreferences>().isOnBoardingViewed()
            ? AppRouter.chooseRole
            : AppRouter.onboarding,
      );
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
