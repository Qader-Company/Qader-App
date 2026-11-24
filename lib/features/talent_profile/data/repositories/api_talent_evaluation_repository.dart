import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/talent_evaluation.dart';
import '../../domain/repositories/talent_evaluation_repository.dart';

/// [TalentEvaluationRepository] backed by `GET /talent/profile/evaluation`.
/// A 404 means the evaluation is not available yet.
class ApiTalentEvaluationRepository implements TalentEvaluationRepository {
  const ApiTalentEvaluationRepository(this._api);
  final ApiConsumer _api;

  static const path = '/talent/profile/evaluation';

  @override
  Future<Either<Failure, TalentEvaluation?>> load() async {
    final result = await _api.get<Object?>(path, fromJson: (raw) => raw);
    if (result.isError) {
      final failure = result.getErrorOrThrow();
      if (failure.statusCode == 404) return const Right(null);
      return Left(failure);
    }
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true || raw['data'] is! Map) {
      return const Left(ServerFailure(message: 'talent_evaluation_failed'));
    }
    try {
      return Right(
        TalentEvaluation.fromJson(
          Map<String, dynamic>.from(raw['data'] as Map),
        ),
      );
    } on Object {
      return const Left(ServerFailure(message: 'talent_evaluation_failed'));
    }
  }
}
