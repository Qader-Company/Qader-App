import '../../app/env/app_env.dart';

/// Placeholder auth paths. Adapt these and the refresh parser to Qader's API.
class EndPoints {
  static String get baseUrl => AppEnv.instance.baseUrl;
  static const login = '/auth/login';
  static const refreshToken = '/auth/refresh';
  static const register = '/auth/register';
  static const verifyOtp = '/auth/email-verification';
  static const resendOtp = '/auth/email-verification/send-otp';
  static const forgotPassword = '/auth/password-reset/send-otp';
  static const verifyResetPasswordOtp = '/auth/reset-password-verification';
  static const resetPassword = '/auth/reset-password';
  static const logout = '/auth/logout';
  static const googleLogin = '/auth/social/google/login';
}
