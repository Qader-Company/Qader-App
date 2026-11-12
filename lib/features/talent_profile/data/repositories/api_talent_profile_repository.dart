import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/talent_profile.dart';
import '../../domain/repositories/talent_profile_repository.dart';

class ApiTalentProfileRepository implements TalentProfileRepository {
  const ApiTalentProfileRepository(this._api);
  final ApiConsumer _api;
  static const profilePath = '/talent/profile';

  @override
  Future<Either<Failure, TalentProfile>> load() async {
    final result = await _api.get<Object?>(profilePath, fromJson: (raw) => raw);
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map ||
        raw['success'] != true ||
        raw['data'] is! Map ||
        (raw['data'] as Map)['sections'] is! List) {
      return const Left(ServerFailure(message: 'talent_invalid_response'));
    }
    try {
      return Right(
        TalentProfile.fromJson(Map<String, dynamic>.from(raw['data'] as Map)),
      );
    } on Object {
      return const Left(ServerFailure(message: 'talent_invalid_response'));
    }
  }
}
