/// Add Qader asset paths after placing files in assets/.
abstract class ImageAssets {
  static const path = 'assets/images';
  static const onboardingPath = '$path/onboarding';
  static const introOpportunities = '$onboardingPath/opportunities.png';
  static const introDashboard = '$onboardingPath/dashboard.png';
  static const introAvatars = [
    '$onboardingPath/avatar_0.png',
    '$onboardingPath/avatar_1.png',
    '$onboardingPath/avatar_2.png',
    '$onboardingPath/avatar_3.png',
    '$onboardingPath/avatar_4.png',
    '$onboardingPath/avatar_5.png',
    '$onboardingPath/avatar_6.png',
  ];
  static const onboardingImages = [
    introOpportunities,
    introDashboard,
    ...introAvatars,
  ];
}

abstract class IconAssets {
  static const path = 'assets/icons';
  static const figmaPath = '$path/figma';
}

abstract class JsonAssets {
  static const path = 'assets/json';
}

abstract class GifAssets {
  static const path = 'assets/gifs';
}
