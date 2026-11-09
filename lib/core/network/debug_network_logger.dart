import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Development-only HTTP console logger (never installed in production; see
/// `DioConsumer`). Prints every request (URL, query, body) and the complete
/// response body. Values of credential-like keys (password, token, OTP, API
/// key, authorization, cookie, secret) are replaced with `[REDACTED]`, and
/// header values are never printed.
class DebugNetworkLogger extends Interceptor {
  DebugNetworkLogger({void Function(String)? log}) : _log = log ?? _console;
  final void Function(String) _log;

  static const _startedAt = 'debug_logger_started_at';

  /// Android's logcat cuts long lines, so print in chunks.
  static void _console(String message) {
    const chunk = 800;
    for (final line in message.split('\n')) {
      for (var i = 0; i < line.length || i == 0; i += chunk) {
        debugPrint(line.substring(i, (i + chunk).clamp(0, line.length)));
      }
    }
  }

  String _request(RequestOptions options) {
    final uri = options.uri;
    final query = {
      for (final entry in uri.queryParametersAll.entries)
        entry.key: _sensitive(entry.key) ? ['[REDACTED]'] : entry.value,
    };
    return '${options.method} '
        '${uri.replace(queryParameters: query.isEmpty ? null : query, fragment: '')}';
  }

  String _duration(RequestOptions options) {
    final started = options.extra[_startedAt];
    return started is DateTime
        ? ' (${DateTime.now().difference(started).inMilliseconds}ms)'
        : '';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAt] = DateTime.now();
    _log('[HTTP] Request ${_request(options)}');
    final data = options.data;
    if (data is FormData) {
      _log(
        '[HTTP] Request FormData ${const JsonEncoder.withIndent('  ').convert({
          'fields': {for (final field in data.fields) field.key: _sensitive(field.key) ? '[REDACTED]' : field.value},
          'files': [for (final file in data.files) '${file.key}: ${file.value.filename ?? 'file'} (${file.value.length} bytes)'],
        })}',
      );
    } else if (data != null && !options.uri.path.contains('/auth/')) {
      // Auth bodies hold credentials; login has its own safe diagnostics.
      _body(data, label: 'Request Body');
    }
    if (options.method == 'POST' &&
        options.uri.path.endsWith('/auth/talent/login')) {
      _loginDiagnostics(options);
    }
    handler.next(options);
  }

  void _loginDiagnostics(RequestOptions options) {
    final data = options.data;
    final email = data is Map && data['email'] is String
        ? data['email'] as String
        : '';
    final password = data is Map && data['password'] is String
        ? data['password'] as String
        : '';
    final at = email.lastIndexOf('@');
    final maskedEmail = at > 0
        ? '${email.substring(0, at > 2 ? 2 : 1)}***${email.substring(at)}'
        : '[invalid email]';
    final headers = {
      for (final entry in options.headers.entries)
        entry.key.toLowerCase(): entry.value,
    };
    final invisible = RegExp(
      r'[\u0000-\u001f\u007f\u200b-\u200f\u202a-\u202e\u2060-\u2069\ufeff]',
    );
    _log(
      '[AuthLogin] ${jsonEncode({'emailMasked': maskedEmail, 'emailLength': email.runes.length, 'emailHasInvisibleCharacters': invisible.hasMatch(email), 'passwordLength': password.runes.length, 'passwordHasEdgeWhitespace': password != password.trim(), 'passwordHasInvisibleCharacters': invisible.hasMatch(password), 'passwordHasNonAscii': password.runes.any((rune) => rune > 127), 'jsonContentType': options.contentType?.contains('application/json') == true, 'apiKeyPresent': headers['x-authorization']?.toString().trim().isNotEmpty == true, 'bearerPresent': headers.containsKey('authorization')})}',
    );
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log(
      '[HTTP] Response ${response.statusCode} '
      '${_request(response.requestOptions)}${_duration(response.requestOptions)}',
    );
    _body(response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      '[HTTP] Error ${err.type.name} '
      'status=${err.response?.statusCode ?? "no response"} '
      '${_request(err.requestOptions)}${_duration(err.requestOptions)}',
    );
    if (err.message case final message? when err.response == null) {
      _log('[HTTP] Error message $message');
    }
    if (err.response != null) _body(err.response!.data);
    handler.next(err);
  }

  void _body(Object? data, {String label = 'Body'}) {
    // Decode textual JSON so secrets cannot bypass structured redaction.
    if (data is String) {
      try {
        data = jsonDecode(data);
      } on FormatException {
        _log('[HTTP] $label (text) $data');
        return;
      }
    }
    _log(
      '[HTTP] $label ${const JsonEncoder.withIndent('  ').convert(_redact(data))}',
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
    return value is num || value is bool || value == null || value is String
        ? value
        : '[${value.runtimeType}]';
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
