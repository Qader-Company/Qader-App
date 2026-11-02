import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/qader_theme.dart';
import 'widgets/application_review_banner.dart';
import 'widgets/application_submitted_notice.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_header.dart';
import 'widgets/home_profile_card.dart';
import 'widgets/review_steps.dart';
import 'widgets/review_faq.dart';

/// Review-state examples are shown only in preview, never as live account data.
class HomeView extends StatelessWidget {
  const HomeView({super.key, this.preview = true});
  final bool preview;

  @override
  Widget build(BuildContext context) => QaderTheme(
    child: Builder(
      builder: (context) => Scaffold(
        backgroundColor: Colors.white,
        drawer: HomeDrawer(preview: preview),
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    alignment: Alignment.topCenter,
                    color: const Color(0xFFF7F7F7),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: preview
                              ? const [
                                  ApplicationReviewBanner(),
                                  SizedBox(height: 24),
                                  ReviewSteps(),
                                  SizedBox(height: 24),
                                  ApplicationSubmittedNotice(),
                                  SizedBox(height: 24),
                                  HomeProfileCard(),
                                  SizedBox(height: 24),
                                  ReviewFaq(),
                                ]
                              : [
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'home'.tr(context: context),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.headlineSmall,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            sl<AppPreferences>().getUserName(),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            sl<AppPreferences>().getUserEmail(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                        ),
                      ),
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
