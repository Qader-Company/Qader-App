import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/network/end_points.dart';
import '../../domain/entities/account_role.dart';

/// Authentication request transport; repositories validate response schemas.
/// API_BASE_URL includes /api/v1. This source never creates a local session.
///
/// Talents and clients share every action under their own prefix
/// (`/auth/talent`, `/auth/client`), with the same request bodies.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._api);
  final ApiConsumer _api;

  Future<Either<Failure, Object?>> login({
    required AccountRole role,
    required String email,
    required String password,
    String? fcmToken,
    String? platform,
  }) => _post(role, 'login', {
    'email': email.trim(),
    'password': password,
    if (fcmToken != null) 'fcm_token': fcmToken,
    if (platform != null) 'platform': platform,
  }, credential: '');

  /// Login with a [provider]'s token (Google: the ID token). Same response
  /// as [login].
  Future<Either<Failure, Object?>> socialLogin({
    required AccountRole role,
    required String provider,
    required String token,
    String? name,
    String? fcmToken,
    String? platform,
  }) => _post(role, 'social/${Uri.encodeComponent(provider)}/login', {
    'token': token,
    if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    if (fcmToken != null) 'fcm_token': fcmToken,
    if (platform != null) 'platform': platform,
  }, credential: '');

  Future<Either<Failure, Object?>> register({
    required AccountRole role,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) => _post(role, 'register', {
    'first_name': firstName.trim(),
    'last_name': lastName.trim(),
    'email': email.trim(),
    'password': password,
    'password_confirmation': passwordConfirmation,
  }, credential: '');

  /// Purpose and credentials must come from the confirmed backend contract.
  Future<Either<Failure, Object?>> sendOtp({
    required AccountRole role,
    required String purpose,
    required String email,
    required String credential,
  }) => _post(role, '${Uri.encodeComponent(purpose)}/send-otp', {
    'email': email.trim(),
  }, credential: credential);

  Future<Either<Failure, Object?>> verifyEmail({
    required AccountRole role,
    required String otp,
    required String credential,
  }) => _api.patch<Object?>(
    '${EndPoints.authPrefix(role.name)}/email-verification',
    authToken: credential,
    data: {'otp': otp},
    fromJson: _raw,
  );

  Future<Either<Failure, Object?>> verifyPasswordResetOtp({
    required AccountRole role,
    required String email,
    required String otp,
    required String credential,
  }) => _post(role, 'reset-password-verification', {
    'email': email.trim(),
    'otp': otp,
  }, credential: credential);

  Future<Either<Failure, Object?>> resetPassword({
    required AccountRole role,
    required String password,
    required String passwordConfirmation,
    required String credential,
  }) => _post(role, 'reset-password', {
    'password': password,
    'password_confirmation': passwordConfirmation,
  }, credential: credential);

  Future<Either<Failure, Object?>> currentUser() =>
      _api.get<Object?>('/auth/me', fromJson: _raw);

  Future<Either<Failure, Object?>> logout() =>
      _api.delete<Object?>('/auth/logout', fromJson: _raw);

  Future<Either<Failure, Object?>> _post(
    AccountRole role,
    String path,
    Map<String, dynamic>? body, {
    required String credential,
  }) => _api.post<Object?>(
    '${EndPoints.authPrefix(role.name)}/$path',
    data: body,
    authToken: credential,
    fromJson: _raw,
  );

  static Object? _raw(dynamic json) => json;
}
