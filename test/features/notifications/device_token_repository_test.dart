import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/notifications/data/repositories/api_device_token_repository.dart';

class _Api extends Fake implements ApiConsumer {
  _Api(this.response);
  final Either<Failure, Object?> response;
  String? path;
  Object? body;

  @override
  Future<Either<Failure, T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? contentType,
    required T Function(dynamic json) fromJson,
  }) async {
    this.path = path;
    body = data;
    return response.fold(Left.new, (raw) => Right(fromJson(raw)));
  }
}

void main() {
  test(
    'PUT device-token sends the token and platform (Apidog example)',
    () async {
      final api = _Api(
        const Right({
          'success': true,
          'message': 'Device token updated successfully.',
          'data': {
            'id': 12,
            'platform': 'android',
            'updated_at': '2026-11-19T14:00:00+02:00',
          },
        }),
      );
      final result = await ApiDeviceTokenRepository(
        api,
      ).register('fcm-token', platform: 'android');
      expect(result.isSuccess, isTrue);
      expect(api.path, '/auth/talent/device-token');
      expect(api.body, {'fcm_token': 'fcm-token', 'platform': 'android'});
    },
  );

  test('a signed-in client sends its token to the client endpoint', () async {
    final api = _Api(const Right({'success': true}));
    await ApiDeviceTokenRepository(
      api,
      role: () => 'client',
    ).register('fcm-token', platform: 'android');
    expect(api.path, '/auth/client/device-token');
  });

  test('a bad body or a failure comes back as a failure', () async {
    final invalid = await ApiDeviceTokenRepository(
      _Api(const Right({'success': false})),
    ).register('t', platform: 'ios');
    expect(invalid.getErrorOrThrow(), isA<ServerFailure>());

    final offline = await ApiDeviceTokenRepository(
      _Api(const Left(NetworkFailure(message: 'offline'))),
    ).register('t', platform: 'ios');
    expect(offline.getErrorOrThrow(), isA<NetworkFailure>());
  });
}
