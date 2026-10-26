import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';

/// Authentication request transport; repositories validate response schemas.
/// API_BASE_URL includes /api/v1. This source never creates a local session.
class TalentAuthRemoteDataSource {
  const TalentAuthRemoteDataSource(this._api);
  final ApiConsumer _api;
  static const _prefix = '/auth/talent';

  Future<Either<Failure, Object?>> login({
    required String email,
    required String password,
    String? fcmToken,
    String? platform,
  }) => _post('login', {
    'email': email.trim(),
    'password': password,
    if (fcmToken != null) 'fcm_token': fcmToken,
    if (platform != null) 'platform': platform,
  }, credential: '');

  Future<Either<Failure, Object?>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) => _post('register', {
    'first_name': firstName.trim(),
    'last_name': lastName.trim(),
    'email': email.trim(),
    'password': password,
    'password_confirmation': passwordConfirmation,
  }, credential: '');

  /// Purpose and credentials must come from the confirmed backend contract.
  Future<Either<Failure, Object?>> sendOtp({
    required String purpose,
    required String email,
    required String credential,
  }) => _post('${Uri.encodeComponent(purpose)}/send-otp', {
    'email': email.trim(),
  }, credential: credential);

  Future<Either<Failure, Object?>> verifyEmail({
    required String otp,
    required String credential,
  }) => _api.patch<Object?>(
    '$_prefix/email-verification',
    authToken: credential,
    data: {'otp': otp},
    fromJson: _raw,
  );

  Future<Either<Failure, Object?>> verifyPasswordResetOtp({
    required String email,
    required String otp,
    required String credential,
  }) => _post('reset-password-verification', {
    'email': email.trim(),
    'otp': otp,
  }, credential: credential);

  Future<Either<Failure, Object?>> resetPassword({
    required String password,
    required String passwordConfirmation,
    required String credential,
  }) => _post('reset-password', {
    'password': password,
    'password_confirmation': passwordConfirmation,
  }, credential: credential);

  Future<Either<Failure, Object?>> refresh({required String credential}) =>
      _post('refresh', null, credential: credential);

  Future<Either<Failure, Object?>> currentUser() =>
      _api.get<Object?>('/auth/me', fromJson: _raw);

  Future<Either<Failure, Object?>> logout() =>
      _api.delete<Object?>('/auth/logout', fromJson: _raw);

  Future<Either<Failure, Object?>> _post(
    String path,
    Map<String, dynamic>? body, {
    required String credential,
  }) => _api.post<Object?>(
    '$_prefix/$path',
    data: body,
    authToken: credential,
    fromJson: _raw,
  );

  static Object? _raw(dynamic json) => json;
}
