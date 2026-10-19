import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/resources/qader_design.dart';
import '../../../../../core/widgets/default_button.dart';
import '../../models/onboarding_page_data.dart';
import 'onboarding_artwork.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.data,
    required this.isLast,
    required this.finishing,
    required this.onNext,
  });
  final OnboardingPageData data;
  final bool isLast;
  final bool finishing;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = constraints.maxWidth / 390;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                SizedBox(height: 64 * scale),
                OnboardingArtwork(kind: data.artwork),
                SizedBox(height: 43 * scale),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: data.titleWidth),
                        child: Text(
                          data.titleKey.tr(context: context),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            height: 32 / 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: data.descriptionWidth,
                        ),
                        child: Text(
                          data.descriptionKey.tr(context: context),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            color: QaderDesign.muted,
                          ),
                        ),
                      ),
                      SizedBox(height: data.buttonGap),
                      DefaultButton.compact(
                        text: (isLast ? 'intro_get_started' : 'intro_next').tr(
                          context: context,
                        ),
                        height: 48,
                        isLoading: finishing,
                        onPressed: finishing ? null : onNext,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
