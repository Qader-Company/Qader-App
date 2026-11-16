import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/onboarding_progress.dart';
import '../../domain/repositories/profile_edit_repository.dart';

class ApiProfileEditRepository implements ProfileEditRepository {
  const ApiProfileEditRepository(this._api);
  final ApiConsumer _api;
  static const profilePath = '/talent/profile';

  @override
  Future<Either<Failure, OnboardingProgress>> load() async {
    final result = await _api.get<Object?>(profilePath, fromJson: (raw) => raw);
    if (result.isError) return Left(result.getErrorOrThrow());
    try {
      return Right(OnboardingProgress.fromProfile(result.getOrThrow()));
    } on Object {
      return const Left(ServerFailure(message: 'profile_progress_failed'));
    }
  }

  /// The body groups fields under their section key, as documented for
  /// Update Profile: `{"personal-information": {...}}`.
  @override
  Future<Either<Failure, void>> updateSection(
    String key,
    Map<String, dynamic> values,
  ) async {
    final result = await _api.patch<Object?>(
      profilePath,
      data: {key: values},
      contentType: 'application/json',
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true) {
      return const Left(ServerFailure(message: 'profile_step_save_failed'));
    }
    return const Right(null);
  }
}
