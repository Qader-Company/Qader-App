import 'package:flutter/material.dart';
import '../../../../../core/resources/assets_manager.dart';
import '../../../../../core/widgets/default_image.dart';
import '../../models/onboarding_page_data.dart';
import 'onboarding_team_artwork.dart';

/// Reference geometry is scaled as one illustration, preserving every crop.
class OnboardingArtwork extends StatelessWidget {
  const OnboardingArtwork({super.key, required this.kind});
  final OnboardingArtworkKind kind;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 390 / 349,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 390,
          height: 349,
          child: kind == OnboardingArtworkKind.team
              ? const OnboardingTeamArtwork()
              : Stack(
                  children: [
                    Positioned(
                      left: 16,
                      top: 44,
                      width: 358,
                      height: 284,
                      child: kind == OnboardingArtworkKind.opportunities
                          ? const ClipRect(
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: -40.633,
                                    top: -.1704,
                                    width: 427.2014,
                                    height: 284.3692,
                                    child: DefaultImage.asset(
                                      assetPath: ImageAssets.introOpportunities,
                                      radius: 0,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const DefaultImage.asset(
                              assetPath: ImageAssets.introDashboard,
                              radius: 0,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}
