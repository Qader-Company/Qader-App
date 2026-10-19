import 'package:flutter/material.dart';
import '../../../../core/widgets/qader_theme.dart';
import 'widgets/application_review_banner.dart';
import 'widgets/application_submitted_notice.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_header.dart';
import 'widgets/home_profile_card.dart';
import 'widgets/review_steps.dart';
import 'widgets/review_faq.dart';

/// Talent dashboard showing the current Under Review preview.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => QaderTheme(
    child: Builder(
      builder: (context) => Scaffold(
        backgroundColor: Colors.white,
        drawer: const HomeDrawer(),
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
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
