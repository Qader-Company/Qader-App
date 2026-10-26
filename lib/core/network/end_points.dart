import '../../app/env/app_env.dart';

/// Talent routes; OTP purpose values still await confirmation.
class EndPoints {
  static String get baseUrl => AppEnv.instance.baseUrl;
  static const login = '/auth/talent/login';
  static const refreshToken = '/auth/talent/refresh';
  static const register = '/auth/talent/register';
  static const verifyOtp = '/auth/talent/email-verification';
  static const resendOtp = '/auth/talent/email-verification/send-otp';
  static const forgotPassword = '/auth/talent/password-reset/send-otp';
  static const verifyResetPasswordOtp =
      '/auth/talent/reset-password-verification';
  static const resetPassword = '/auth/talent/reset-password';
  static const logout = '/auth/logout';
  static const googleLogin = '/auth/talent/social/google/login';
}
