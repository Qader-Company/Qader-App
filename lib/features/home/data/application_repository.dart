import '../../../core/network/api_consumer.dart';
import '../../../core/network/either.dart';
import '../../../core/network/failure.dart';
import '../domain/talent_application.dart';

class ApplicationRepository {
  const ApplicationRepository(this._api);
  final ApiConsumer _api;
  static const applicationPath = '/talent/application';

  Future<Either<Failure, TalentApplication>> load() async {
    final result = await _api.get<Object?>(
      applicationPath,
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true || raw['data'] is! Map) {
      return const Left(ServerFailure(message: 'application_invalid_response'));
    }
    try {
      return Right(
        TalentApplication.fromJson(
          Map<String, dynamic>.from(raw['data'] as Map),
        ),
      );
    } on Object {
      return const Left(ServerFailure(message: 'application_invalid_response'));
    }
  }
}
