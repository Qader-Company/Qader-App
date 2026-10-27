import 'package:flutter/material.dart';
import '../../../../../core/resources/assets_manager.dart';
import '../../../../../core/widgets/default_image.dart';
import '../../models/onboarding_page_data.dart';

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
          child: Stack(
            children: [
              Positioned(
                left: kind == OnboardingArtworkKind.team ? 4 : 16,
                top: kind == OnboardingArtworkKind.team ? 25 : 44,
                width: kind == OnboardingArtworkKind.team ? 382 : 358,
                height: kind == OnboardingArtworkKind.team ? 303 : 284,
                child: kind == OnboardingArtworkKind.team
                    ? const DefaultImage.asset(
                        assetPath: ImageAssets.introTeam,
                        radius: 0,
                        fit: BoxFit.cover,
                      )
                    : kind == OnboardingArtworkKind.opportunities
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
