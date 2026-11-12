import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../domain/talent_application.dart';
import '../cubit/application_cubit.dart';
import 'application_status_view.dart';
import 'widgets/application_review_banner.dart';
import 'widgets/application_submitted_notice.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_header.dart';
import 'widgets/home_profile_card.dart';
import 'widgets/review_steps.dart';
import 'widgets/review_faq.dart';
import '../../../../core/resources/app_colors.dart';
import '../../domain/repositories/application_repository.dart';
import '../../../../core/di/maybe_read.dart';
import '../../../../core/widgets/locale_change_listener.dart';

/// Talent home. In [preview] it shows the static "Under Review" design;
/// otherwise it loads `GET /talent/application` and shows the screen that
/// matches its `screen_state`.
class HomeView extends StatelessWidget {
  const HomeView({super.key, this.preview = true});
  final bool preview;

  @override
  Widget build(BuildContext context) {
    if (preview) {
      return const _Dashboard(
        preview: true,
        children: [
          ApplicationReviewBanner(),
          SizedBox(height: 24),
          ReviewSteps(),
          SizedBox(height: 24),
          ApplicationSubmittedNotice(),
          SizedBox(height: 24),
          HomeProfileCard(),
          SizedBox(height: 24),
          ReviewFaq(),
        ],
      );
    }
    return BlocProvider(
      create: (context) =>
          ApplicationCubit(context.read<ApplicationRepository>())..load(),
      // Backend labels and FAQs follow the app language: reload on change.
      child: Builder(
        builder: (context) => LocaleChangeListener(
          onChanged: context.read<ApplicationCubit>().load,
          child: BlocBuilder<ApplicationCubit, ApplicationState>(
            builder: _buildState,
          ),
        ),
      ),
    );
  }

  Widget _buildState(BuildContext context, ApplicationState state) {
    final cubit = context.read<ApplicationCubit>();
    final application = state.application;
    if (application == null) {
      return _Dashboard(
        preview: false,
        children: [
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 120),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _LoadError(onRetry: cubit.load),
        ],
      );
    }
    if (application.viewStatus case final status?) {
      return ApplicationStatusView(
        key: ValueKey(status),
        initialStatus: status,
        application: application,
        userName: _userName(context),
        onRefresh: cubit.load,
        onSelectSlot: (slotId) async =>
            (await cubit.selectSlot(slotId))?.message,
        onRejectSlots: (reason) async =>
            (await cubit.rejectSlots(reason))?.message,
        onCancelInterview: () async => (await cubit.cancelInterview())?.message,
      );
    }
    return _Dashboard(
      preview: false,
      onRefresh: cubit.load,
      children: _underReview(context, application),
    );
  }

  List<Widget> _underReview(
    BuildContext context,
    TalentApplication application,
  ) {
    final faqs = application.screenFaqs;
    return [
      ApplicationReviewBanner(name: _userName(context)),
      const SizedBox(height: 24),
      const ReviewSteps(),
      const SizedBox(height: 24),
      const ApplicationSubmittedNotice(),
      // Backend FAQs for this screen only; none → no FAQ card.
      if (faqs.isNotEmpty) ...[
        const SizedBox(height: 24),
        ReviewFaq(
          items: [
            for (final faq in faqs)
              (question: faq.question, answer: faq.answer),
          ],
        ),
      ],
    ];
  }
}

String _userName(BuildContext context) {
  final user = context.maybeRead<AuthSessionCubit>()?.state.user;
  if (user != null && user.fullName.isNotEmpty) return user.fullName;
  return context.maybeRead<AppPreferences>()?.getUserName() ?? '';
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.preview,
    required this.children,
    this.onRefresh,
  });
  final bool preview;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        alignment: Alignment.topCenter,
        color: AppColors.background,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
    if (onRefresh case final refresh?) {
      content = RefreshIndicator(onRefresh: refresh, child: content);
    }
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: HomeDrawer(preview: preview),
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),
            Expanded(
              child: ColoredBox(color: AppColors.background, child: content),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 8),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 40,
          color: AppColors.neutral500,
        ),
        const SizedBox(height: 12),
        Text(
          'home_we_couldn_t_load_your_application_status'.tr(context: context),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 20 / 14),
        ),
        const SizedBox(height: 16),
        DefaultButton.compact(
          height: 40,
          text: 'home_try_again'.tr(context: context),
          onPressed: onRetry,
        ),
      ],
    ),
  );
}
