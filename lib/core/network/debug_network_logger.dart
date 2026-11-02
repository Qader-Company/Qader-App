import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Installed only in debug builds. Logs safe login diagnostics, never raw
/// request bodies, passwords, tokens, or header values.
class DebugNetworkLogger extends Interceptor {
  DebugNetworkLogger({void Function(String)? log})
    : _log = log ?? ((message) => debugPrint(message));
  final void Function(String) _log;

  String _request(RequestOptions options) =>
      '${options.method} ${options.uri.replace(query: '', fragment: '')}';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('[HTTP] Request ${_request(options)}');
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
