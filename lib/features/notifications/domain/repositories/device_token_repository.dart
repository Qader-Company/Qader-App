import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';

/// Where the signed-in talent's devices receive pushes.
abstract class DeviceTokenRepository {
  /// Saves this installation's FCM [token] for the signed-in talent.
  /// [platform] is `android`, `ios` or `web`.
  Future<Either<Failure, void>> register(
    String token, {
    required String platform,
  });
}
