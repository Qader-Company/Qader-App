import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/debug_network_logger.dart';
import 'network_session_test.dart' show CallbackAdapter, jsonResponse;

void main() {
  test(
    'response logging redacts nested credentials without changing the response',
    () async {
      final logs = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      addTearDown(dio.close);
      dio.interceptors.add(DebugNetworkLogger(log: logs.add));
      dio.httpClientAdapter = CallbackAdapter(
        (_) async => jsonResponse({
          'success': true,
          'message': 'Signed in',
          'data': {
            'access_token': {'token': 'private-access'},
            'items': [
              {
                'password_confirmation': 'private-password',
                'otp': '123456',
                'id': 2,
              },
            ],
          },
        }, 200),
      );
      final response = await dio.post<dynamic>(
        '/login?api_key=private-query',
        data: {'password': 'private-request'},
        options: Options(headers: {'Authorization': 'Bearer private-header'}),
      );
      final output = logs.join('\n');
      expect(output, contains('Response 200'));
      expect(output, contains('Signed in'));
      expect(output, contains('[REDACTED]'));
      for (final secret in [
        'private-access',
        'private-password',
        '123456',
        'private-query',
        'private-request',
        'private-header',
      ]) {
        expect(output, isNot(contains(secret)));
      }
      expect(response.data['data']['access_token']['token'], 'private-access');
    },
  );

  test(
    'HTTP errors show status and server message; network errors show type',
    () async {
      final logs = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      addTearDown(dio.close);
      dio.interceptors.add(DebugNetworkLogger(log: logs.add));
      dio.httpClientAdapter = CallbackAdapter(
        (_) async => jsonResponse({
          'message': 'Invalid credentials',
          'reset_password_token': 'private-reset',
        }, 422),
      );
      await expectLater(
        dio.post<dynamic>('/login'),
        throwsA(isA<DioException>()),
      );
      expect(logs.join('\n'), contains('status=422'));
      expect(logs.join('\n'), contains('Invalid credentials'));
      expect(logs.join('\n'), isNot(contains('private-reset')));
      logs.clear();
      dio.httpClientAdapter = CallbackAdapter(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        ),
      );
      await expectLater(
        dio.post<dynamic>('/login'),
        throwsA(isA<DioException>()),
      );
      expect(logs.join('\n'), contains('connectionTimeout'));
      expect(logs.join('\n'), contains('no response'));
    },
  );

  test('non-JSON response text is omitted', () async {
    final logs = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    addTearDown(dio.close);
    dio.interceptors.add(DebugNetworkLogger(log: logs.add));
    dio.httpClientAdapter = CallbackAdapter(
      (_) async => jsonResponse('private non-JSON text', 200),
    );
    await dio.get<dynamic>('/text');
    expect(logs.join('\n'), contains('Non-JSON response body omitted'));
    expect(logs.join('\n'), isNot(contains('private non-JSON text')));
  });
}
