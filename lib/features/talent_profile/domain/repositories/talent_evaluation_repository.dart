import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/talent_evaluation.dart';

/// The signed-in talent's evaluation.
abstract class TalentEvaluationRepository {
  /// `null` when no evaluation is available yet.
  Future<Either<Failure, TalentEvaluation?>> load();
}
