import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/client_auth_remote_data_source.dart';
import '../models/auth_response.dart';

class ClientAuthRepository implements AuthRepository {
  ClientAuthRepository(this._remote, this._preferences);
  final ClientAuthRemoteDataSource _remote;
  final AppPreferences _preferences;

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
  Future<Either<Failure, AuthUser>> currentUser() async {
    final result = await _remote.currentUser();
    return result.fold((failure) => Left(failure), (raw) {
      try {
        final user = AuthResponse.user(AuthResponse.data(raw));
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
    });
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
