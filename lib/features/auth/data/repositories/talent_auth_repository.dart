import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/email_verification_challenge.dart';
import '../../domain/entities/account_role.dart';
import '../../domain/entities/registration_request.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/talent_auth_remote_data_source.dart';
import '../models/auth_response.dart';

class TalentAuthRepository implements AuthRepository {
  TalentAuthRepository(this._remote, this._preferences);
  final TalentAuthRemoteDataSource _remote;
  final AppPreferences _preferences;
  EmailVerificationChallenge? _challenge;
  int _registrationOperation = 0;

  @override
  Future<Either<Failure, AuthUser>> login(String email, String password) async {
    final revision = _preferences.sessionRevision.value;
    final result = await _remote.login(email: email, password: password);
    if (revision != _preferences.sessionRevision.value) {
      return const Left(ServerFailure(message: 'auth_session_changed'));
    }
    return result.fold((failure) async => Left(failure), (raw) async {
      try {
        final data = AuthResponse.data(raw);
        final user = AuthResponse.user(data);
        if (user.role != AccountRole.talent) {
          return const Left(ServerFailure(message: 'auth_wrong_role'));
        }
        final access = AuthResponse.token(data, 'access_token');
        final refresh = AuthResponse.token(data, 'refresh_token');
        if (!user.isActive || !user.isEmailVerified) {
          return Left(
            ServerFailure(
              message: !user.isActive
                  ? 'auth_account_inactive'
                  : 'auth_email_unverified',
            ),
          );
        }
        await _preferences.saveUserName(user.fullName);
        await _preferences.setUserEmail(user.email);
        await _preferences.setUserId(user.id);
        await _preferences.saveRefreshToken(refresh);
        if (revision != _preferences.sessionRevision.value) {
          return const Left(ServerFailure(message: 'auth_session_changed'));
        }
        // Access is written last, so routing never sees a half-created session.
        await _preferences.saveToken(access);
        return Right(user);
      } on FormatException {
        return const Left(ServerFailure(message: 'auth_invalid_response'));
      } on Object {
        await _preferences.logout();
        return const Left(CacheFailure(message: 'auth_storage_error'));
      }
    });
  }

  @override
  Future<Either<Failure, EmailVerificationChallenge>> register(
    RegistrationRequest request,
  ) async {
    final operation = ++_registrationOperation;
    final revision = _preferences.sessionRevision.value;
    final result = await _remote.register(
      firstName: request.firstName,
      lastName: request.lastName,
      email: request.email,
      password: request.password,
      passwordConfirmation: request.passwordConfirmation,
    );
    if (operation != _registrationOperation ||
        revision != _preferences.sessionRevision.value) {
      return const Left(ServerFailure(message: 'auth_session_changed'));
    }
    if (result.isError) return Left(result.getErrorOrThrow());
    try {
      final data = AuthResponse.data(result.getOrThrow());
      final user = AuthResponse.user(data);
      final token = AuthResponse.token(data, 'verification_token');
      if (user.role != AccountRole.talent) {
        return const Left(ServerFailure(message: 'auth_wrong_role'));
      }
      final challenge = EmailVerificationChallenge(email: user.email);
      await _preferences.saveVerificationToken(token);
      if (operation != _registrationOperation ||
          revision != _preferences.sessionRevision.value) {
        return const Left(ServerFailure(message: 'auth_session_changed'));
      }
      _challenge = challenge;
      return Right(challenge);
    } on FormatException {
      return const Left(ServerFailure(message: 'auth_invalid_response'));
    } on Object {
      return const Left(CacheFailure(message: 'auth_storage_error'));
    }
  }

  @override
  Future<Either<Failure, void>> resendVerificationEmail(
    EmailVerificationChallenge challenge,
  ) async {
    final revision = _preferences.sessionRevision.value;
    if (!identical(challenge, _challenge) ||
        _preferences.getVerificationToken().isEmpty) {
      return const Left(ServerFailure(message: 'auth_verification_missing'));
    }
    final result = await _remote.sendOtp(
      purpose: 'email-verification',
      email: challenge.email,
      credential: '',
    );
    if (!identical(challenge, _challenge) ||
        revision != _preferences.sessionRevision.value) {
      return const Left(ServerFailure(message: 'auth_session_changed'));
    }
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true) {
      return const Left(ServerFailure(message: 'auth_invalid_response'));
    }
    // Some responses rotate the verification credential; acknowledgements keep it.
    final data = raw['data'];
    if (data is Map && data.containsKey('verification_token')) {
      try {
        final token = AuthResponse.token(
          Map<String, dynamic>.from(data),
          'verification_token',
        );
        await _preferences.saveVerificationToken(token);
      } on FormatException {
        return const Left(ServerFailure(message: 'auth_invalid_response'));
      } on Object {
        return const Left(CacheFailure(message: 'auth_storage_error'));
      }
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> verifyEmail(
    EmailVerificationChallenge challenge,
    String otp,
  ) async {
    final token = _preferences.getVerificationToken();
    final revision = _preferences.sessionRevision.value;
    if (!identical(challenge, _challenge) || token.isEmpty) {
      return const Left(ServerFailure(message: 'auth_verification_missing'));
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      return const Left(ServerFailure(message: 'auth_otp_invalid'));
    }
    final result = await _remote.verifyEmail(otp: otp, credential: token);
    if (!identical(challenge, _challenge) ||
        revision != _preferences.sessionRevision.value) {
      return const Left(ServerFailure(message: 'auth_session_changed'));
    }
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true) {
      return const Left(ServerFailure(message: 'auth_invalid_response'));
    }
    try {
      await _preferences.clearVerificationToken();
      _challenge = null;
      // Verification acknowledgement does not establish a login session.
      return const Right(null);
    } on Object {
      return const Left(CacheFailure(message: 'auth_storage_error'));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> currentUser() async {
    final result = await _remote.currentUser();
    if (result.isError) return Left(result.getErrorOrThrow());
    try {
      final user = AuthResponse.user(AuthResponse.data(result.getOrThrow()));
      if (user.role != AccountRole.talent) {
        // Retire a client session left by the previous integration.
        await _preferences.logout();
        return const Left(ServerFailure(message: 'auth_wrong_role'));
      }
      if (!user.isActive || !user.isEmailVerified) {
        return Left(
          ServerFailure(
            message: !user.isActive
                ? 'auth_account_inactive'
                : 'auth_email_unverified',
          ),
        );
      }
      return Right(user);
    } on FormatException {
      return const Left(ServerFailure(message: 'auth_invalid_response'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final result = await _remote.logout();
      return result.mapRight<void>((_) {});
    } finally {
      await _preferences.logout();
    }
  }
}
