import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../di/service_locator.dart';
import '../router/app_router.dart';
import '../storage/app_preferences.dart';
import 'end_points.dart';
import '../../app/env/app_env.dart';

/// Custom Dio interceptor that handles automatic token refresh.
///
/// Flow:
///  1. Every request goes out normally with the current access_token.
///  2. If the server returns 401 (Unauthorized), we attempt a token refresh:
///     - Send the refresh_token as a Bearer in the Authorization header
///       to [EndPoints.refreshToken].
///     - On success: save the new access_token (and refresh_token if rotated),
///       then retry the original request transparently.
///     - On failure: clear all tokens and emit [AppEvents.logout] so the app
///       navigates the user back to the login screen.
class AppInterceptors extends Interceptor {
  /// A separate Dio instance used ONLY for the refresh call, so it
  /// doesn't recurse back into this interceptor.
  AppInterceptors({Dio? refreshDio})
    : _refreshDio =
          refreshDio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 60),
            ),
          );

  final Dio _refreshDio;

  /// Guard flag to prevent concurrent refresh attempts.
  Future<String?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['sessionRevision'] =
        sl<AppPreferences>().sessionRevision.value;
    if (kDebugMode && options.path.endsWith(EndPoints.googleLogin)) {
      final headers = {
        for (final entry in options.headers.entries)
          entry.key.toLowerCase(): entry.value,
      };
      final apiKey = headers['x-authorization']?.toString() ?? '';
      debugPrint(
        '[GoogleSignIn] Request metadata: '
        'apiKeyPresent=${apiKey.trim().isNotEmpty}, '
        'apiKeyLength=${apiKey.length}, '
        'authorizationPresent=${headers.containsKey(HttpHeaders.authorizationHeader)}, '
        'contentType=${options.contentType}',
      );
    }
    handler.next(options);
  }

  bool _isCurrent(RequestOptions options) =>
      options.extra['sessionRevision'] ==
      sl<AppPreferences>().sessionRevision.value;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!_isCurrent(response.requestOptions)) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.cancel,
          message: 'Session changed',
        ),
      );
      return;
    }
    handler.next(response);
  }

  /// Auth endpoints that should NOT trigger token refresh or force logout on 401.
  /// These are public endpoints where 401 means a real API error (e.g. wrong credentials).
  static const _publicAuthPaths = {
    EndPoints.login,
    EndPoints.googleLogin,
    EndPoints.register,
    EndPoints.verifyOtp,
    EndPoints.resendOtp,
    EndPoints.forgotPassword,
    EndPoints.verifyResetPasswordOtp,
    EndPoints.resetPassword,
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only intercept 401 Unauthorized responses.
    if (err.response?.statusCode != 401 || !_isCurrent(err.requestOptions)) {
      return handler.next(err);
    }

    // Skip refresh logic for public auth endpoints — just pass the error through
    // so the UI can display the server's error message (e.g. "unauthorized process").
    final body = err.response?.data;
    if (body is Map && body['message'] == 'api.unauthorized') {
      return handler.next(err);
    }
    final requestPath = err.requestOptions.path;
    final isPublicEndpoint = _publicAuthPaths.any(
      (p) => requestPath.endsWith(p),
    );
    if (isPublicEndpoint) {
      return handler.next(err);
    }

    final prefs = sl<AppPreferences>();
    final refreshToken = prefs.getRefreshToken();

    // If we have no refresh token, there's nothing we can do → logout.
    if (refreshToken.isEmpty) {
      await _forceLogout(prefs);
      return handler.next(err);
    }

    try {
      var token = prefs.getToken();
      if (err.requestOptions.headers[HttpHeaders.authorizationHeader] ==
          'Bearer $token') {
        final pending = _refreshing ??= _refresh(
          prefs,
          prefs.sessionRevision.value,
        );
        try {
          token = await pending ?? '';
        } finally {
          if (identical(_refreshing, pending)) _refreshing = null;
        }
      }
      if (!_isCurrent(err.requestOptions) || token.isEmpty) {
        return handler.next(err);
      }
      final original = err.requestOptions;
      final retryOptions = original.copyWith(
        headers: {
          ...original.headers,
          HttpHeaders.authorizationHeader: 'Bearer $token',
        },
        data: original.data is FormData
            ? (original.data as FormData).clone()
            : original.data,
      );
      final response = await _refreshDio.fetch<dynamic>(retryOptions);
      if (!_isCurrent(original)) return handler.next(err);
      return handler.resolve(response);
    } on DioException catch (error) {
      return handler.reject(error);
    } catch (error) {
      return handler.reject(
        DioException(requestOptions: err.requestOptions, error: error),
      );
    }
  }

  static String? _readToken(dynamic value) {
    final token = value is Map ? value['token'] : value;
    return token is String && token.isNotEmpty ? token : null;
  }

  Future<String?> _refresh(AppPreferences prefs, int revision) async {
    final refreshToken = prefs.getRefreshToken();
    try {
      // ── Call the refresh endpoint ──────────────────────────────────────
      // The API expects the refresh_token as a Bearer token in the header.
      final refreshResponse = await _refreshDio.post(
        '${EndPoints.baseUrl}${EndPoints.refreshToken}',
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $refreshToken',
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.acceptHeader: 'application/json',
            'Accept-Language': prefs.getAppLanguage(),
            if (AppEnv.instance.hasApiKey)
              'X-Authorization': AppEnv.instance.apiKey,
          },
        ),
      );

      // ── Parse the new tokens ───────────────────────────────────────────
      if (prefs.sessionRevision.value != revision) return null;
      final raw = refreshResponse.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      final newAccessToken = data is Map
          ? _readToken(data['access_token'])
          : null;
      final newRefreshToken = data is Map
          ? _readToken(data['refresh_token'])
          : null;

      if (newAccessToken == null) {
        // Malformed response — treat as expired.
        throw const FormatException('Invalid refresh response');
      }

      // ── Persist the new tokens ─────────────────────────────────────────
      await prefs.saveToken(newAccessToken);
      if (prefs.sessionRevision.value != revision) return null;
      if (newRefreshToken != null) {
        await prefs.saveRefreshToken(newRefreshToken);
      }

      // ── Retry the original request with the new access_token ───────────
      return newAccessToken;
    } on DioException catch (error) {
      // Refresh call itself failed (e.g. refresh_token expired) → logout.
      if (prefs.sessionRevision.value == revision &&
          (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403)) {
        await _forceLogout(prefs);
      }
      rethrow;
    }
  }

  /// Clears the session and returns to root. Set the auth route when ready.
  Future<void> _forceLogout(AppPreferences prefs) async {
    await prefs.logout();
    // Navigate to root — safe to call from any isolate via post-frame callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!prefs.isLoggedIn) {
        navigatorKey.currentContext?.go('${AppRouter.signIn}?role=talent');
      }
    });
  }
}
