import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/repositories/device_token_repository.dart';

/// [DeviceTokenRepository] backed by `PUT /auth/<role>/device-token`, for
/// the signed-in role ([role] returns `talent` or `client`).
class ApiDeviceTokenRepository implements DeviceTokenRepository {
  const ApiDeviceTokenRepository(this._api, {String Function()? role})
    : _role = role;
  final ApiConsumer _api;
  final String Function()? _role;

  /// A session saved before roles were stored is a talent session.
  String get path =>
      '/auth/${_role?.call() == 'client' ? 'client' : 'talent'}/device-token';

  @override
  Future<Either<Failure, void>> register(
    String token, {
    required String platform,
  }) async {
    final result = await _api.put<Object?>(
      path,
      data: {'fcm_token': token, 'platform': platform},
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true) {
      return const Left(
        ServerFailure(message: 'device_token_invalid_response'),
      );
    }
    return const Right(null);
  }
}
