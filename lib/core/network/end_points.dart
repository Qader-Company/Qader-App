import '../../app/env/app_env.dart';

/// Client routes; OTP purpose values still await confirmation.
class EndPoints {
  static String get baseUrl => AppEnv.instance.baseUrl;
  static const login = '/auth/client/login';
  static const refreshToken = '/auth/client/refresh';
  static const register = '/auth/client/register';
  static const verifyOtp = '/auth/client/email-verification';
  static const resendOtp = '/auth/client/email-verification/send-otp';
  static const forgotPassword = '/auth/client/password-reset/send-otp';
  static const verifyResetPasswordOtp =
      '/auth/client/reset-password-verification';
  static const resetPassword = '/auth/client/reset-password';
  static const logout = '/auth/logout';
  static const googleLogin = '/auth/client/social/google/login';
}
