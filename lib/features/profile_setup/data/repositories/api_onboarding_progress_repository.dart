import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/onboarding_progress.dart';
import '../../domain/repositories/onboarding_progress_repository.dart';

class ApiOnboardingProgressRepository implements OnboardingProgressRepository {
  const ApiOnboardingProgressRepository(this.api);
  final ApiConsumer api;
  @override
  Future<Either<Failure, OnboardingProgress>> load() async {
    final result = await api.get<Object?>(
      '/talent/onboarding',
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    try {
      return Right(OnboardingProgress.fromJson(result.getOrThrow()));
    } on Object {
      return const Left(ServerFailure(message: 'profile_progress_failed'));
    }
  }
}
