import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/onboarding_progress.dart';

abstract class OnboardingProgressRepository {
  Future<Either<Failure, OnboardingProgress>> load();
}
