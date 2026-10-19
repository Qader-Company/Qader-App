import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/app/env/app_env.dart';
import 'package:qader/core/di/service_locator.dart';
import 'package:qader/core/network/app_interceptors.dart';
import 'package:qader/core/storage/app_preferences.dart';

class CallbackAdapter implements HttpClientAdapter {
  CallbackAdapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object body, int status) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppPreferences prefs;
  late Dio client;
  late Dio refresh;
  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    prefs = AppPreferencesImpl(await SharedPreferences.getInstance());
    sl.registerSingleton<AppPreferences>(prefs);
    await prefs.saveToken('old');
    await prefs.saveRefreshToken('refresh');
    AppEnv.init(Environment.dev);
    client = Dio(BaseOptions(baseUrl: 'https://example.test'));
    refresh = Dio();
    client.interceptors.add(AppInterceptors(refreshDio: refresh));
  });
  tearDown(() async {
    client.close();
    refresh.close();
    await sl.reset();
  });

  test('concurrent 401s share one refresh and both requests retry', () async {
    final bothUnauthorized = Completer<void>();
    var unauthorized = 0;
    var refreshes = 0;
    client.httpClientAdapter = CallbackAdapter((request) async {
      if (++unauthorized == 2) bothUnauthorized.complete();
      return jsonResponse({}, 401);
    });
    refresh.httpClientAdapter = CallbackAdapter((request) async {
      if (request.path.endsWith('/refresh')) {
        refreshes++;
        await bothUnauthorized.future;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return jsonResponse({
          'data': {
            'access_token': {'token': 'new'},
          },
        }, 200);
      }
      expect(request.headers['authorization'], 'Bearer new');
      return jsonResponse({'ok': true}, 200);
    });
    final responses = await Future.wait([
      client.get<dynamic>(
        '/one',
        options: Options(headers: {'authorization': 'Bearer old'}),
      ),
      client.get<dynamic>(
        '/two',
        options: Options(headers: {'authorization': 'Bearer old'}),
      ),
    ]);
    expect(responses.every((response) => response.statusCode == 200), isTrue);
    expect(refreshes, 1);
    expect(prefs.getRefreshToken(), 'refresh');
    expect(prefs.getToken(), 'new');
  });

  test('refresh network failure preserves login', () async {
    client.httpClientAdapter = CallbackAdapter(
      (_) async => jsonResponse({}, 401),
    );
    refresh.httpClientAdapter = CallbackAdapter(
      (request) async => throw DioException(
        requestOptions: request,
        type: DioExceptionType.connectionTimeout,
      ),
    );
    await expectLater(
      client.get<dynamic>(
        '/one',
        options: Options(headers: {'authorization': 'Bearer old'}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(prefs.getToken(), 'old');
  });

  test(
    'retried operation failure does not log out a renewed session',
    () async {
      client.httpClientAdapter = CallbackAdapter(
        (_) async => jsonResponse({}, 401),
      );
      refresh.httpClientAdapter = CallbackAdapter(
        (request) async => request.path.endsWith('/refresh')
            ? jsonResponse({'access_token': 'new'}, 200)
            : jsonResponse({}, 500),
      );
      await expectLater(
        client.get<dynamic>(
          '/one',
          options: Options(headers: {'authorization': 'Bearer old'}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(prefs.getToken(), 'new');
    },
  );

  test('logout during refresh cannot restore old tokens', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    client.httpClientAdapter = CallbackAdapter(
      (_) async => jsonResponse({}, 401),
    );
    refresh.httpClientAdapter = CallbackAdapter((_) async {
      started.complete();
      await release.future;
      return jsonResponse({'access_token': 'old-user-new-token'}, 200);
    });
    final request = client.get<dynamic>(
      '/one',
      options: Options(headers: {'authorization': 'Bearer old'}),
    );
    final expectation = expectLater(request, throwsA(isA<DioException>()));
    await started.future;
    await prefs.logout();
    await prefs.saveToken('different-user');
    release.complete();
    await expectation;
    expect(prefs.getToken(), 'different-user');
  });

  test('multipart is cloned before replay after refresh', () async {
    client.httpClientAdapter = CallbackAdapter((request) async {
      expect((request.data as FormData).isFinalized, isTrue);
      return jsonResponse({}, 401);
    });
    refresh.httpClientAdapter = CallbackAdapter((request) async {
      if (request.path.endsWith('/refresh')) {
        return jsonResponse({'access_token': 'new'}, 200);
      }
      return jsonResponse({'ok': true}, 200);
    });
    final result = await client.post<dynamic>(
      '/upload',
      data: FormData.fromMap({
        'image': MultipartFile.fromBytes([1, 2, 3], filename: 'test.jpg'),
      }),
      options: Options(headers: {'authorization': 'Bearer old'}),
    );
    expect(result.statusCode, 200);
  });
}
