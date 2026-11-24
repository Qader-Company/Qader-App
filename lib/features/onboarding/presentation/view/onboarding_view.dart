import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/resources/qader_design.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/app_toast.dart';
import '../cubit/onboarding_cubit.dart';
import '../models/onboarding_page_data.dart';
import 'widgets/onboarding_page.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => OnboardingCubit(context.read<AppPreferences>()),
    child: BlocListener<OnboardingCubit, OnboardingStatus>(
      listener: (context, status) {
        if (status == OnboardingStatus.done) context.go(AppRouter.chooseRole);
        if (status == OnboardingStatus.failed) {
          showAppToast(
            context,
            'intro_save_failed'.tr(context: context),
            type: ToastType.error,
          );
        }
      },
      child: const _Pages(),
    ),
  );
}

/// The intro pages and the progress bar; the page index is local UI state.
class _Pages extends StatefulWidget {
  const _Pages();
  @override
  State<_Pages> createState() => _PagesState();
}

class _PagesState extends State<_Pages> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < onboardingPages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    context.read<OnboardingCubit>().finish();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.white,
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
                  backgroundColor: AppColors.neutral100,
                  semanticsLabel: 'intro_step'.tr(
                    context: context,
                    args: ['${_index + 1}', '${onboardingPages.length}'],
                  ),
                ),
              ),
              Expanded(
                // Only the button's busy state follows the cubit.
                child: BlocSelector<OnboardingCubit, OnboardingStatus, bool>(
                  selector: (status) =>
                      status == OnboardingStatus.finishing ||
                      status == OnboardingStatus.done,
                  builder: (context, finishing) => PageView.builder(
                    controller: _controller,
                    itemCount: onboardingPages.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (context, index) => OnboardingPage(
                      data: onboardingPages[index],
                      isLast: index == onboardingPages.length - 1,
                      finishing: finishing,
                      onNext: _next,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
