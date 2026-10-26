import 'package:qader/features/auth/domain/entities/registration_request.dart';
import 'package:qader/features/auth/presentation/cubit/registration_cubit.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/auth/data/datasources/talent_auth_remote_data_source.dart';
import 'package:qader/features/auth/data/repositories/talent_auth_repository.dart';
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
  Future<Either<Failure, T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic) fromJson,
  }) => post(path, data: data, authToken: authToken, fromJson: fromJson);

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
      'last_name': 'Talent',
      'email': 'talent@example.test',
      'type': 'talent',
      'is_active': true,
      'email_verified_at': verified ? '2026-01-01T00:00:00Z' : null,
    },
    'access_token': {'token': 'access', 'ttl': 60},
    'refresh_token': {'token': 'refresh', 'ttl': 1440},
  },
};

Map<String, Object?> registrationResponse() => {
  'success': true,
  'message': 'auth.verify_account',
  'data': {
    'user': {
      'id': 12,
      'first_name': 'Demo',
      'last_name': 'Talent',
      'email': 'talent@example.test',
      'type': 'talent',
      'is_active': false,
      'email_verified_at': null,
    },
    'verification_token': {'token': 'verification-only', 'ttl': 60},
  },
};
const registrationRequest = RegistrationRequest(
  firstName: 'Demo',
  lastName: 'Talent',
  email: 'talent@example.test',
  password: 'password123',
  passwordConfirmation: 'password123',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppPreferences prefs;
  late AuthApi api;
  late TalentAuthRepository repository;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = AppPreferencesImpl(await SharedPreferences.getInstance());
    api = AuthApi()..response = loginResponse();
    repository = TalentAuthRepository(TalentAuthRemoteDataSource(api), prefs);
  });
  test('login parses observed response and saves a complete session', () async {
    final result = await repository.login(
      ' talent@example.test ',
      'password123',
    );
    expect(result.isSuccess, isTrue);
    expect(result.getOrThrow().fullName, 'Test Talent');
    expect(prefs.getToken(), 'access');
    expect(prefs.getRefreshToken(), 'refresh');
    expect(api.path, '/auth/talent/login');
    expect(api.body, {
      'email': 'talent@example.test',
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

  test('client response cannot establish a Talent session', () async {
    final wrongRole = loginResponse();
    ((wrongRole['data'] as Map)['user'] as Map)['type'] = 'client';
    api.response = wrongRole;
    expect((await repository.login('email', 'password')).isError, isTrue);
    expect(prefs.isLoggedIn, isFalse);
  });

  test('restoring an old client session clears it', () async {
    await prefs.saveToken('client-token');
    final wrongRole = loginResponse();
    ((wrongRole['data'] as Map)['user'] as Map)['type'] = 'client';
    api.response = wrongRole;
    expect((await repository.currentUser()).isError, isTrue);
    expect(prefs.isLoggedIn, isFalse);
  });

  test(
    'registration success never authenticates and double submit is ignored',
    () async {
      api.response = registrationResponse();
      api.gate = Completer<void>();
      final cubit = RegistrationCubit(repository);
      const request = RegistrationRequest(
        firstName: 'Demo',
        lastName: 'Talent',
        email: 'talent@example.test',
        password: 'password123',
        passwordConfirmation: 'password123',
      );
      final pending = cubit.submit(request);
      await cubit.submit(request);
      expect(api.calls, 1);
      api.gate!.complete();
      await pending;
      expect(cubit.state.status, RegistrationStatus.success);
      expect(prefs.isLoggedIn, isFalse);
      await cubit.submit(request);
      expect(api.calls, 1);
      await cubit.close();
    },
  );

  test('registration does not accept a non-success envelope', () async {
    api.response = {'message': 'not a success'};
    final result = await repository.register(
      const RegistrationRequest(
        firstName: 'Demo',
        lastName: 'Talent',
        email: 'talent@example.test',
        password: 'password123',
        passwordConfirmation: 'password123',
      ),
    );
    expect(result.isError, isTrue);
    expect(prefs.isLoggedIn, isFalse);
  });
  test(
    'registration saves only verification credentials and rejects malformed data',
    () async {
      api.response = registrationResponse();
      final result = await repository.register(registrationRequest);
      expect(result.getOrThrow().email, 'talent@example.test');
      expect(prefs.getVerificationToken(), 'verification-only');
      expect(prefs.getToken(), isEmpty);
      expect(prefs.getRefreshToken(), isEmpty);
      api.response = {'success': true, 'data': {}};
      expect((await repository.register(registrationRequest)).isError, isTrue);
    },
  );

  test(
    'verification uses its own token, retries errors and clears it only on success',
    () async {
      api.response = registrationResponse();
      final challenge = (await repository.register(
        registrationRequest,
      )).getOrThrow();
      expect(
        (await repository.verifyEmail(challenge, '12345')).isError,
        isTrue,
      );
      expect(api.calls, 1);
      api.failure = const ServerFailure(message: 'Invalid OTP');
      expect(
        (await repository.verifyEmail(challenge, '123456')).isError,
        isTrue,
      );
      expect(api.path, '/auth/talent/email-verification');
      expect(api.body, {'otp': '123456'});
      expect(api.credential, 'verification-only');
      expect(prefs.getVerificationToken(), 'verification-only');
      api.failure = null;
      api.response = {'success': true};
      expect(
        (await repository.verifyEmail(challenge, '123456')).isSuccess,
        isTrue,
      );
      expect(prefs.getVerificationToken(), isEmpty);
      expect(prefs.isLoggedIn, isFalse);
      expect(
        (await repository.verifyEmail(challenge, '123456')).isError,
        isTrue,
      );
    },
  );

  test(
    'an old verification screen cannot use a newer registration token',
    () async {
      api.response = registrationResponse();
      final old = (await repository.register(registrationRequest)).getOrThrow();
      await repository.register(registrationRequest);
      expect((await repository.verifyEmail(old, '123456')).isError, isTrue);
      expect(api.calls, 2);
    },
  );

  test('logout during registration discards the late challenge', () async {
    api.response = registrationResponse();
    api.gate = Completer<void>();
    final pending = repository.register(registrationRequest);
    await prefs.logout();
    api.gate!.complete();
    expect((await pending).isError, isTrue);
    expect(prefs.getVerificationToken(), isEmpty);
  });
}
