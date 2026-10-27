import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/entities/account_role.dart';
import '../../domain/entities/password_recovery_request.dart';
import '../datasources/talent_auth_remote_data_source.dart';

/// Reset credentials are separate from login and email-verification credentials.
class PasswordRecoveryRepository {
  PasswordRecoveryRepository(this._remote, this._preferences);
  final TalentAuthRemoteDataSource _remote;
  final AppPreferences _preferences;
  PasswordRecoveryRequest? _request;
  bool _verified = false;
  int _operation = 0;
  int? _revision;

  bool _current(PasswordRecoveryRequest request) =>
      identical(request, _request) &&
      _revision == _preferences.sessionRevision.value;

  static bool _ack(Object? raw) => raw is Map && raw['success'] == true;
  static const _missing = ServerFailure(message: 'auth_recovery_missing');
  static const _invalid = ServerFailure(message: 'auth_invalid_response');

  Future<Either<Failure, PasswordRecoveryRequest>> begin(String email) async {
    final operation = ++_operation;
    final revision = _preferences.sessionRevision.value;
    _request = null;
    _verified = false;
    await _preferences.clearResetPasswordToken();
    final result = await _remote.sendOtp(
      purpose: 'password-reset',
      email: email,
      credential: '',
    );
    if (operation != _operation ||
        revision != _preferences.sessionRevision.value) {
      return const Left(_missing);
    }
    if (result.isError) return Left(result.getErrorOrThrow());
    if (!_ack(result.getOrThrow())) return const Left(_invalid);
    final request = PasswordRecoveryRequest(
      email: email.trim(),
      role: AccountRole.talent,
    );
    _request = request;
    _revision = revision;
    return Right(request);
  }

  Future<Either<Failure, void>> resend(PasswordRecoveryRequest request) async {
    if (!_current(request) || _verified) return const Left(_missing);
    final result = await _remote.sendOtp(
      purpose: 'password-reset',
      email: request.email,
      credential: '',
    );
    if (!_current(request)) return const Left(_missing);
    if (result.isError) return Left(result.getErrorOrThrow());
    return _ack(result.getOrThrow()) ? const Right(null) : const Left(_invalid);
  }

  Future<Either<Failure, void>> verify(
    PasswordRecoveryRequest request,
    String otp,
  ) async {
    if (!_current(request) || _verified) return const Left(_missing);
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      return const Left(ServerFailure(message: 'auth_otp_invalid'));
    }
    final result = await _remote.verifyPasswordResetOtp(
      email: request.email,
      otp: otp,
      credential: '',
    );
    if (!_current(request)) return const Left(_missing);
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (!_ack(raw)) return const Left(_invalid);
    final data = (raw as Map)['data'];
    final credential = data is Map ? data['reset_password_token'] : null;
    final token = credential is Map ? credential['token'] : credential;
    if (token is! String || token.trim().isEmpty) return const Left(_invalid);
    await _preferences.saveResetPasswordToken(token);
    if (!_current(request)) return const Left(_missing);
    _verified = true;
    return const Right(null);
  }

  Future<Either<Failure, void>> reset(
    PasswordRecoveryRequest request,
    String password,
    String confirmation,
  ) async {
    final token = _preferences.getResetPasswordToken();
    if (!_current(request) || !_verified || token.isEmpty) {
      return const Left(_missing);
    }
    if (password.length < 8 || password != confirmation) {
      return const Left(ServerFailure(message: 'auth_reset_password_invalid'));
    }
    final result = await _remote.resetPassword(
      password: password,
      passwordConfirmation: confirmation,
      credential: token,
    );
    if (!_current(request)) return const Left(_missing);
    if (result.isError) return Left(result.getErrorOrThrow());
    if (!_ack(result.getOrThrow())) return const Left(_invalid);
    await _preferences.clearResetPasswordToken();
    _request = null;
    _verified = false;
    return const Right(null);
  }
}
