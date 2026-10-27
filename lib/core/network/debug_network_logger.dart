import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Installed only in debug builds. Never logs request bodies or headers.
class DebugNetworkLogger extends Interceptor {
  DebugNetworkLogger({void Function(String)? log})
    : _log = log ?? ((message) => debugPrint(message));
  final void Function(String) _log;

  String _request(RequestOptions options) =>
      '${options.method} ${options.uri.replace(query: '', fragment: '')}';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('[HTTP] Request ${_request(options)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log(
      '[HTTP] Response ${response.statusCode} ${_request(response.requestOptions)}',
    );
    _body(response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      '[HTTP] Error ${err.type.name} '
      'status=${err.response?.statusCode ?? "no response"} ${_request(err.requestOptions)}',
    );
    if (err.response != null) _body(err.response!.data);
    handler.next(err);
  }

  void _body(Object? data) {
    // Decode textual JSON so secrets cannot bypass structured redaction.
    if (data is String) {
      try {
        data = jsonDecode(data);
      } on FormatException {
        _log('[HTTP] Non-JSON response body omitted');
        return;
      }
    }
    _log(
      '[HTTP] Body ${const JsonEncoder.withIndent('  ').convert(_redact(data))}',
    );
  }

  Object? _redact(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _sensitive(entry.key.toString())
              ? '[REDACTED]'
              : _redact(entry.value),
      };
    }
    if (value is List) return value.map(_redact).toList();
    return value is num || value is bool || value == null
        ? value
        : value is String
        ? value
        : '[Non-JSON value]';
  }

  bool _sensitive(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return [
      'token',
      'password',
      'secret',
      'authorization',
      'cookie',
      'apikey',
      'otp',
      'credential',
    ].any(normalized.contains);
  }
}
