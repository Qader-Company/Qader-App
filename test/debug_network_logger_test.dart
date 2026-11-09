import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/debug_network_logger.dart';
import 'network_session_test.dart' show CallbackAdapter, jsonResponse;

void main() {
  test(
    'login diagnostics identify input anomalies without exposing credentials',
    () async {
      final logs = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      addTearDown(dio.close);
      dio.interceptors.add(DebugNetworkLogger(log: logs.add));
      dio.httpClientAdapter = CallbackAdapter(
        (_) async => jsonResponse({'success': true}, 200),
      );
      const password = ' Secret\u200b١! ';
      await dio.post<dynamic>(
        '/api/v1/auth/talent/login',
        data: {'email': 'tester@example.test', 'password': password},
        options: Options(
          contentType: 'application/json',
          headers: {'X-Authorization': 'private-key'},
        ),
      );
      final output = logs.join('\n');
      expect(output, contains('[AuthLogin]'));
      expect(output, contains('"emailMasked":"te***@example.test"'));
      expect(output, contains('"passwordLength":11'));
      expect(output, contains('"passwordHasEdgeWhitespace":true'));
      expect(output, contains('"passwordHasInvisibleCharacters":true'));
      expect(output, contains('"passwordHasNonAscii":true'));
      expect(output, contains('"apiKeyPresent":true'));
      expect(output, contains('"bearerPresent":false'));
      for (final secret in [
        password,
        'Secret',
        'tester@example.test',
        'private-key',
      ]) {
        expect(output, isNot(contains(secret)));
      }
      logs.clear();
      await dio.post<dynamic>(
        '/api/v1/auth/talent/register',
        data: {'email': 'tester@example.test', 'password': password},
      );
      expect(logs.join('\n'), isNot(contains('[AuthLogin]')));
    },
  );
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

  test('logs request query/body and non-JSON response text', () async {
    final logs = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    addTearDown(dio.close);
    dio.interceptors.add(DebugNetworkLogger(log: logs.add));
    dio.httpClientAdapter = CallbackAdapter(
      (_) async => jsonResponse('plain server text', 200),
    );
    await dio.post<dynamic>(
      '/slots?page=2&token=private-token',
      data: {'slot_id': 7, 'reason': 'busy', 'otp': '99999'},
    );
    final output = logs.join('\n');
    expect(output, contains('page=2'));
    expect(output, contains('"slot_id": 7'));
    expect(output, contains('"reason": "busy"'));
    expect(output, contains('plain server text'));
    expect(output, matches(RegExp(r'Response 200 .*\(\d+ms\)')));
    expect(output, isNot(contains('private-token')));
    expect(output, isNot(contains('99999')));
  });
}
