import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/resources/qader_design.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/qader_theme.dart';
import '../models/onboarding_page_data.dart';
import 'widgets/onboarding_page.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_finishing) return;
    if (_index < onboardingPages.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    setState(() => _finishing = true);
    try {
      await sl<AppPreferences>().setOnBoardingViewed();
      if (mounted) context.go(AppRouter.chooseRole);
    } catch (_) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('intro_save_failed'.tr(context: context))),
      );
    }
  }

  @override
  Widget build(BuildContext context) => QaderTheme(
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    value: onboardingPages[_index].progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: QaderDesign.blue,
                    backgroundColor: const Color(0xFFF5F5F5),
                    semanticsLabel: 'intro_step'.tr(
                      context: context,
                      args: ['${_index + 1}', '${onboardingPages.length}'],
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: onboardingPages.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (context, index) => OnboardingPage(
                      data: onboardingPages[index],
                      isLast: index == onboardingPages.length - 1,
                      finishing: _finishing,
                      onNext: _next,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
