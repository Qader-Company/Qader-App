import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_preferences.dart';

/// Keeps synchronous token reads for Dio while persisting only in secure storage.
class SecureAppPreferences extends AppPreferencesImpl {
  SecureAppPreferences._(super.preferences, this._storage, this._tokens);
  final FlutterSecureStorage _storage;
  Map<String, String> _tokens;
  Future<void> _pending = Future<void>.value();
  static const _key = 'qader.auth.tokens';
  int _generation = 0;

  static Future<SecureAppPreferences> create(
    SharedPreferences preferences, {
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) async {
    final raw = await storage.read(key: _key);
    Map<String, String> tokens = {};
    if (raw != null) {
      try {
        tokens = Map<String, String>.from(jsonDecode(raw) as Map);
      } on Object {
        await storage.delete(key: _key);
      }
    }
    // Retire placeholder/plaintext sessions instead of migrating untrusted tokens.
    for (final key in [
      'PREFS_KEY_TOKEN',
      'PREFS_KEY_REFRESH_TOKEN',
      'PREFS_KEY_VERIFICATION_TOKEN',
      'PREFS_KEY_RESET_PASSWORD_TOKEN',
    ]) {
      await preferences.remove(key);
    }
    return SecureAppPreferences._(preferences, storage, tokens);
  }

  Future<void> _update(void Function(Map<String, String>) update) {
    final generation = _generation;
    final operation = _pending.then((_) async {
      if (generation != _generation) return;
      final next = Map<String, String>.from(_tokens);
      update(next);
      if (next.isEmpty) {
        await _storage.delete(key: _key);
      } else {
        await _storage.write(key: _key, value: jsonEncode(next));
      }
      if (generation == _generation) _tokens = next;
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  @override
  String getToken() => _tokens['access'] ?? '';
  @override
  String getRefreshToken() => _tokens['refresh'] ?? '';
  @override
  String getVerificationToken() => _tokens['verification'] ?? '';
  @override
  String getResetPasswordToken() => _tokens['reset'] ?? '';
  @override
  Future<void> saveToken(String token) async {
    final startsSession = getToken().isEmpty && token.isNotEmpty;
    await _update((tokens) => tokens['access'] = token);
    if (startsSession && getToken() == token) sessionRevision.value++;
  }

  @override
  Future<void> saveRefreshToken(String token) =>
      _update((tokens) => tokens['refresh'] = token);
  @override
  Future<void> saveVerificationToken(String token) =>
      _update((tokens) => tokens['verification'] = token);
  @override
  Future<void> clearVerificationToken() =>
      _update((tokens) => tokens.remove('verification'));
  @override
  Future<void> saveResetPasswordToken(String token) =>
      _update((tokens) => tokens['reset'] = token);
  @override
  Future<void> clearResetPasswordToken() =>
      _update((tokens) => tokens.remove('reset'));
  @override
  Future<void> logout() async {
    // Invalidate in-flight requests immediately, before awaiting disk I/O.
    _generation++;
    _tokens = {};
    final clearPreferences = super.logout();
    await _update((tokens) => tokens.clear());
    await clearPreferences;
  }
}
