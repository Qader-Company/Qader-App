enum OnboardingArtworkKind { opportunities, team, dashboard }

class OnboardingPageData {
  const OnboardingPageData({
    required this.titleKey,
    required this.descriptionKey,
    required this.artwork,
    required this.progress,
    required this.buttonGap,
    this.descriptionWidth = 314,
    this.titleWidth = 294,
  });
  final String titleKey;
  final String descriptionKey;
  final OnboardingArtworkKind artwork;
  final double progress;
  final double buttonGap;
  final double descriptionWidth;
  final double titleWidth;
}

const onboardingPages = [
  OnboardingPageData(
    titleKey: 'intro_opportunities_title',
    descriptionKey: 'intro_opportunities_description',
    artwork: OnboardingArtworkKind.opportunities,
    progress: .1375,
    buttonGap: 48,
  ),
  OnboardingPageData(
    titleKey: 'intro_team_title',
    descriptionKey: 'intro_team_description',
    artwork: OnboardingArtworkKind.team,
    titleWidth: 358,
    progress: .4906,
    buttonGap: 72,
  ),
  OnboardingPageData(
    titleKey: 'intro_dashboard_title',
    descriptionKey: 'intro_dashboard_description',
    artwork: OnboardingArtworkKind.dashboard,
    titleWidth: 358,
    progress: 1,
    buttonGap: 72,
    descriptionWidth: 300,
  ),
];
