import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../locale/language_manager.dart';

abstract class _Keys {
  static const lang = 'lang_key';
  static const onBoarding = 'PREFS_KEY_ON_BOARDING';
  static const token = 'PREFS_KEY_TOKEN';
  static const refreshToken = 'PREFS_KEY_REFRESH_TOKEN';
  static const verificationToken = 'PREFS_KEY_VERIFICATION_TOKEN';
  static const resetPasswordToken = 'PREFS_KEY_RESET_PASSWORD_TOKEN';
  static const userName = 'PREFS_KEY_USER_NAME';
  static const userImage = 'PREFS_KEY_USER_IMAGE';
  static const userPhone = 'PREFS_KEY_USER_PHONE';
  static const userEmail = 'PREFS_KEY_USER_EMAIL';
  static const userId = 'PREFS_KEY_USER_ID';
  static const locationPermissionPrompted =
      'PREFS_KEY_LOCATION_PERMISSION_PROMPTED';
}

/// Abstract interface for app preferences — allows mocking in tests.
abstract class AppPreferences {
  ValueNotifier<int> get sessionRevision;
  // ──── Language ────
  String getAppLanguage();
  Future<void> setAppLanguage(String langCode);
  Future<Locale> getLocale();

  // ──── OnBoarding ────
  bool isOnBoardingViewed();
  Future<void> setOnBoardingViewed();

  // ──── Token ────
  String getToken();
  Future<void> saveToken(String token);
  String getRefreshToken();
  Future<void> saveRefreshToken(String token);
  bool get isLoggedIn;

  // ──── Verification Token (used between register & verify OTP) ────
  String getVerificationToken();
  Future<void> saveVerificationToken(String token);
  Future<void> clearVerificationToken();

  // ──── Reset Password Token (used between verifyResetPasswordOtp & resetPassword) ────
  String getResetPasswordToken();
  Future<void> saveResetPasswordToken(String token);
  Future<void> clearResetPasswordToken();

  // ──── User Info ────
  String getUserName();
  Future<void> saveUserName(String name);
  String? getUserImage();
  Future<void> saveUserImage(String url);
  String getUserPhone();
  Future<void> setUserPhone(String phone);
  String getUserEmail();
  Future<void> setUserEmail(String email);
  int getUserId();
  Future<void> setUserId(int id);

  // ── Location permission prompt ─────────────────────────────────────────
  bool hasLocationPermissionPrompted();
  Future<void> setLocationPermissionPrompted();

  // ──── Logout ────
  Future<void> logout();
}

/// Concrete SharedPreferences implementation of [AppPreferences].
class AppPreferencesImpl implements AppPreferences {
  final SharedPreferences _prefs;
  final Future<void> Function()? clearSessionData;

  @override
  final ValueNotifier<int> sessionRevision = ValueNotifier(0);

  AppPreferencesImpl(this._prefs, {this.clearSessionData});

  // ──── Language ────
  @override
  String getAppLanguage() =>
      _prefs.getString(_Keys.lang) ?? LanguageType.english.code;

  @override
  Future<void> setAppLanguage(String langCode) =>
      _prefs.setString(_Keys.lang, langCode);

  @override
  Future<Locale> getLocale() async {
    final lang = getAppLanguage();
    return lang == LanguageType.english.code ? englishLocale : arabicLocale;
  }

  // ──── OnBoarding ────
  @override
  bool isOnBoardingViewed() => _prefs.getBool(_Keys.onBoarding) ?? false;

  @override
  Future<void> setOnBoardingViewed() => _prefs.setBool(_Keys.onBoarding, true);

  // ──── Token ────
  @override
  String getToken() => _prefs.getString(_Keys.token) ?? '';

  @override
  Future<void> saveToken(String token) async {
    final startsSession = getToken().isEmpty && token.isNotEmpty;
    await _prefs.setString(_Keys.token, token);
    if (startsSession) sessionRevision.value++;
  }

  @override
  String getRefreshToken() => _prefs.getString(_Keys.refreshToken) ?? '';

  @override
  Future<void> saveRefreshToken(String token) =>
      _prefs.setString(_Keys.refreshToken, token);

  @override
  bool get isLoggedIn => getToken().isNotEmpty;

  // ──── Verification Token ────
  @override
  String getVerificationToken() =>
      _prefs.getString(_Keys.verificationToken) ?? '';

  @override
  Future<void> saveVerificationToken(String token) =>
      _prefs.setString(_Keys.verificationToken, token);

  @override
  Future<void> clearVerificationToken() =>
      _prefs.remove(_Keys.verificationToken);

  // ──── Reset Password Token ────
  @override
  String getResetPasswordToken() =>
      _prefs.getString(_Keys.resetPasswordToken) ?? '';

  @override
  Future<void> saveResetPasswordToken(String token) =>
      _prefs.setString(_Keys.resetPasswordToken, token);

  @override
  Future<void> clearResetPasswordToken() =>
      _prefs.remove(_Keys.resetPasswordToken);

  // ──── User Info ────
  @override
  String getUserName() => _prefs.getString(_Keys.userName) ?? '';

  @override
  Future<void> saveUserName(String name) =>
      _prefs.setString(_Keys.userName, name);

  @override
  String? getUserImage() => _prefs.getString(_Keys.userImage);

  @override
  Future<void> saveUserImage(String url) =>
      _prefs.setString(_Keys.userImage, url);

  @override
  String getUserPhone() => _prefs.getString(_Keys.userPhone) ?? '';

  @override
  Future<void> setUserPhone(String phone) =>
      _prefs.setString(_Keys.userPhone, phone);

  @override
  String getUserEmail() => _prefs.getString(_Keys.userEmail) ?? '';

  @override
  Future<void> setUserEmail(String email) =>
      _prefs.setString(_Keys.userEmail, email);

  @override
  int getUserId() => _prefs.getInt(_Keys.userId) ?? 0;

  @override
  Future<void> setUserId(int id) => _prefs.setInt(_Keys.userId, id);

  // ── Location permission prompt ─────────────────────────────────────────
  @override
  bool hasLocationPermissionPrompted() =>
      _prefs.getBool(_Keys.locationPermissionPrompted) ?? false;

  @override
  Future<void> setLocationPermissionPrompted() =>
      _prefs.setBool(_Keys.locationPermissionPrompted, true);

  // ──── Logout ────
  @override
  Future<void> logout() async {
    sessionRevision.value++;
    try {
      await clearSessionData?.call();
    } catch (_) {
      // A filesystem cleanup failure must not keep the account signed in.
    }
    final lang = getAppLanguage();
    final onBoarding = isOnBoardingViewed();
    await _prefs.clear();
    await setAppLanguage(lang);
    if (onBoarding) await setOnBoardingViewed();
  }
}
