import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/onboarding_progress.dart';
import 'onboarding_progress_repository.dart';

/// Editing a saved profile through `/talent/profile`. Its sections have the
/// same shape as the onboarding steps, so the setup forms are reused.
abstract class ProfileEditRepository implements OnboardingProgressRepository {
  /// `GET /talent/profile` as an editable snapshot.
  @override
  Future<Either<Failure, OnboardingProgress>> load();

  /// `PATCH /talent/profile` with one section ([key] is one of
  /// [OnboardingProgress.keys]). Values are API IDs and enum codes.
  Future<Either<Failure, void>> updateSection(
    String key,
    Map<String, dynamic> values,
  );
}
