import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/profile_cv.dart';

/// Values must contain API IDs and enum codes, never translated UI labels.
abstract class OnboardingStepsRepository {
  Future<Either<Failure, void>> savePersonalInformation(
    Map<String, dynamic> values, {
    required Set<String> visibleFields,
    ProfileCv? cv,
  });

  Future<Either<Failure, void>> saveSkillsAndExperiences(
    Map<String, dynamic> values, {
    required Set<String> visibleFields,
    Map<int, List<ProfileCv>> projectImages = const {},
  });

  Future<Either<Failure, void>> saveWorkPreferences(
    Map<String, dynamic> values, {
    required Set<String> visibleFields,
  });
}
