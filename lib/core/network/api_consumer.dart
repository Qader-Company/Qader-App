import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../app/env/app_env.dart';
import '../di/service_locator.dart';
import '../storage/app_preferences.dart';
import 'app_interceptors.dart';
import 'either.dart';

import 'failure.dart';

abstract class ApiConsumer {
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  });

  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic json) fromJson,
  });

  Future<Either<Failure, T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? contentType,
    required T Function(dynamic json) fromJson,
  });

  Future<Either<Failure, T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic json) fromJson,
  });

  Future<Either<Failure, T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  });
}

class DioConsumer implements ApiConsumer {
  final Dio _dio;

  DioConsumer({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppEnv.instance.baseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 15)
      ..sendTimeout = const Duration(seconds: 60)
      ..receiveDataWhenStatusError = true;

    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        return client;
      };
    }

    _dio.interceptors.add(AppInterceptors());
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: false,
        ),
      );
    }
  }

  Map<String, dynamic> _headers({
    bool isFormData = false,
    String? authToken,
    String? contentType,
  }) {
    final prefs = sl<AppPreferences>();
    // Use explicit authToken if provided, otherwise fall back to stored token.
    final token = authToken ?? prefs.getToken();
    return {
      if (contentType != null)
        HttpHeaders.contentTypeHeader: contentType
      else if (!isFormData)
        HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
      'Accept-Language': prefs.getAppLanguage(),
      if (AppEnv.instance.apiKey.isNotEmpty)
        'X-Authorization': AppEnv.instance.apiKey,
      if (token.isNotEmpty && token != 'dev_token_placeholder')
        HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: _headers()),
      );
      return Right(fromJson(response.data));
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final isFormData = data is FormData;
      final effectiveContentType =
          contentType ?? (isFormData ? null : 'application/json');
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: _headers(
            isFormData: isFormData,
            authToken: authToken,
            contentType: effectiveContentType,
          ),
          contentType: effectiveContentType,
        ),
      );
      return Right(fromJson(response.data));
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? contentType,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final isFormData = data is FormData;
      final effectiveContentType =
          contentType ?? (isFormData ? null : 'application/json');
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: _headers(
            isFormData: isFormData,
            contentType: effectiveContentType,
          ),
          contentType: effectiveContentType,
        ),
      );
      return Right(fromJson(response.data));
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final isFormData = data is FormData;
      final effectiveContentType =
          contentType ?? (isFormData ? null : 'application/json');
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: _headers(
            isFormData: isFormData,
            authToken: authToken,
            contentType: effectiveContentType,
          ),
          contentType: effectiveContentType,
        ),
      );
      return Right(fromJson(response.data));
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: Options(headers: _headers()),
      );
      return Right(fromJson(response.data));
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  Failure _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const TimeoutFailure(message: 'Connection timeout');
        case DioExceptionType.badResponse:
          return _handleBadResponse(error);
        case DioExceptionType.cancel:
          return const ServerFailure(message: 'Request cancelled');
        case DioExceptionType.connectionError:
          return const NetworkFailure(message: 'No internet connection');
        case DioExceptionType.badCertificate:
          return const ServerFailure(message: 'Bad certificate');
        case DioExceptionType.unknown:
        default:
          return const NetworkFailure(message: 'Connection error');
      }
    }
    return UnknownFailure(message: error.toString());
  }

  Failure _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    String message = 'Unknown error';

    if (error.response?.data is Map) {
      final data = error.response!.data as Map;
      message =
          data['message']?.toString() ??
          data['msg']?.toString() ??
          data['error']?.toString() ??
          message;

      if (data['errors'] is Map) {
        final errors = data['errors'] as Map<String, dynamic>;
        final messages = <String>[];
        errors.forEach((key, value) {
          if (value is List) {
            messages.addAll(value.map((e) => e.toString()));
          } else if (value is String) {
            messages.add(value);
          }
        });
        if (messages.isNotEmpty) {
          return ValidationFailure(
            message: messages.first,
            errors: messages,
            statusCode: statusCode,
          );
        }
      } else if (data['errors'] is List) {
        final errors = data['errors'] as List;
        if (errors.isNotEmpty) {
          final messages = errors.map((e) => e.toString()).toList();
          return ValidationFailure(
            message: messages.first,
            errors: messages,
            statusCode: statusCode,
          );
        }
      } else if (data['errors'] is String &&
          (data['errors'] as String).isNotEmpty) {
        return ValidationFailure(
          message: data['errors'].toString(),
          errors: [data['errors'].toString()],
          statusCode: statusCode,
        );
      }
    } else if (error.response?.data is String &&
        (error.response!.data as String).isNotEmpty) {
      message = error.response!.data as String;
    }

    if (statusCode == 401) {
      return UnauthorizedFailure(message: message);
    }
    return ServerFailure(
      message: message,
      statusCode: statusCode,
      responseData: error.response?.data,
    );
  }
}
