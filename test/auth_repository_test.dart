import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/auth/data/datasources/client_auth_remote_data_source.dart';
import 'package:qader/features/auth/data/repositories/client_auth_repository.dart';
import 'package:qader/features/auth/presentation/cubit/auth_session_cubit.dart';

class AuthApi extends Fake implements ApiConsumer {
  Object? response;
  Failure? failure;
  Completer<void>? gate;
  int calls = 0;
  String? path;
  Map<String, dynamic>? body;
  String? credential;
  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic) fromJson,
  }) async {
    calls++;
    this.path = path;
    body = data as Map<String, dynamic>?;
    credential = authToken;
    await gate?.future;
    return failure == null ? Right(fromJson(response)) : Left(failure!);
  }

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async => failure == null ? Right(fromJson(response)) : Left(failure!);
  @override
  Future<Either<Failure, T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async => failure == null ? Right(fromJson(response)) : Left(failure!);
}

Map<String, Object?> loginResponse({bool verified = true}) => {
  'success': true,
  'data': {
    'user': {
      'id': 2,
      'first_name': 'Test',
      'last_name': 'Client',
      'email': 'client@example.test',
      'is_active': true,
      'email_verified_at': verified ? '2026-01-01T00:00:00Z' : null,
    },
    'access_token': {'token': 'access', 'ttl': 60},
    'refresh_token': {'token': 'refresh', 'ttl': 1440},
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppPreferences prefs;
  late AuthApi api;
  late ClientAuthRepository repository;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = AppPreferencesImpl(await SharedPreferences.getInstance());
    api = AuthApi()..response = loginResponse();
    repository = ClientAuthRepository(ClientAuthRemoteDataSource(api), prefs);
  });
  test('login parses observed response and saves a complete session', () async {
    final result = await repository.login(
      ' client@example.test ',
      'password123',
    );
    expect(result.isSuccess, isTrue);
    expect(result.getOrThrow().fullName, 'Test Client');
    expect(prefs.getToken(), 'access');
    expect(prefs.getRefreshToken(), 'refresh');
    expect(api.path, '/auth/client/login');
    expect(api.body, {
      'email': 'client@example.test',
      'password': 'password123',
    });
    expect(api.credential, '');
  });
  test('malformed response cannot create a session', () async {
    api.response = {
      'success': true,
      'data': {
        'access_token': {'token': 'access'},
      },
    };
    expect((await repository.login('email', 'password')).isError, isTrue);
    expect(prefs.isLoggedIn, isFalse);
  });
  test('unverified account is never granted a full session', () async {
    api.response = loginResponse(verified: false);
    expect((await repository.login('email', 'password')).isError, isTrue);
    expect(prefs.isLoggedIn, isFalse);
    expect(prefs.getRefreshToken(), isEmpty);
  });
  test('logout during login discards the late response', () async {
    api.gate = Completer<void>();
    final pending = repository.login('email', 'password');
    await prefs.logout();
    api.gate!.complete();
    expect((await pending).isError, isTrue);
    expect(prefs.isLoggedIn, isFalse);
  });
  test('server logout failure still clears local credentials', () async {
    await prefs.saveToken('access');
    await prefs.saveRefreshToken('refresh');
    api.failure = const NetworkFailure(message: 'offline');
    expect((await repository.logout()).isError, isTrue);
    expect(prefs.isLoggedIn, isFalse);
    expect(prefs.getRefreshToken(), isEmpty);
  });
  test('duplicate submissions issue only one request', () async {
    api.gate = Completer<void>();
    final cubit = AuthSessionCubit(repository, prefs);
    final pending = cubit.login('email', 'password');
    await cubit.login('email', 'password');
    expect(api.calls, 1);
    api.gate!.complete();
    await pending;
    expect(cubit.state.status, AuthStatus.authenticated);
    await cubit.close();
  });
  test('restore retains the session on a temporary network error', () async {
    await prefs.saveToken('access');
    api.failure = const NetworkFailure(message: 'offline');
    final cubit = AuthSessionCubit(repository, prefs);
    await cubit.restore();
    expect(cubit.state.status, AuthStatus.failure);
    expect(prefs.isLoggedIn, isTrue);
    await cubit.close();
  });
}
