import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/qader_theme.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../domain/talent_application.dart';
import '../cubit/application_cubit.dart';
import '../status_copy.dart';
import 'application_status_view.dart';
import 'widgets/application_review_banner.dart';
import 'widgets/application_submitted_notice.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_header.dart';
import 'widgets/home_profile_card.dart';
import 'widgets/review_steps.dart';
import 'widgets/review_faq.dart';

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
      create: (_) => sl<ApplicationCubit>()..load(),
      child: BlocBuilder<ApplicationCubit, ApplicationState>(
        builder: (context, state) {
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
              userName: _userName(),
              onRefresh: cubit.load,
              onSelectSlot: (slotId) async =>
                  (await cubit.selectSlot(slotId))?.message,
              onRejectSlots: (reason) async =>
                  (await cubit.rejectSlots(reason))?.message,
              onCancelInterview: () async =>
                  (await cubit.cancelInterview())?.message,
            );
          }
          return _Dashboard(
            preview: false,
            onRefresh: cubit.load,
            children: _underReview(application),
          );
        },
      ),
    );
  }

  List<Widget> _underReview(TalentApplication application) {
    final faqs = application.screenFaqs;
    return [
      ApplicationReviewBanner(name: _userName()),
      const SizedBox(height: 24),
      const ReviewSteps(),
      const SizedBox(height: 24),
      const ApplicationSubmittedNotice(),
      const SizedBox(height: 24),
      ReviewFaq(
        items: faqs.isEmpty
            ? null
            : [
                for (final faq in faqs)
                  (question: faq.question, answer: faq.answer),
              ],
      ),
    ];
  }
}

String _userName() {
  final user = sl<AuthSessionCubit>().state.user;
  if (user != null && user.fullName.isNotEmpty) return user.fullName;
  return sl<AppPreferences>().getUserName();
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
        color: const Color(0xFFF7F7F7),
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
    return QaderTheme(
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: HomeDrawer(preview: preview),
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(),
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFFF7F7F7),
                  child: content,
                ),
              ),
            ],
          ),
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
          color: Color(0xFF737373),
        ),
        const SizedBox(height: 12),
        Text(
          sc(
            context,
            "We couldn't load your application status.",
            'تعذر تحميل حالة طلبك.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 20 / 14),
        ),
        const SizedBox(height: 16),
        DefaultButton.compact(
          height: 40,
          text: sc(context, 'Try again', 'إعادة المحاولة'),
          onPressed: onRetry,
        ),
      ],
    ),
  );
}
