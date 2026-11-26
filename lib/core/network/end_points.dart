import '../env/app_env.dart';

/// Auth routes. Talents and clients share the same actions under their own
/// prefix: `/auth/talent/...` or `/auth/client/...`.
class EndPoints {
  static String get baseUrl => AppEnv.instance.baseUrl;

  /// The auth prefix of a role name (`talent` or `client`).
  static String authPrefix(String role) => '/auth/$role';

  /// Refresh endpoint of the signed-in role; a session saved before roles
  /// were stored is a talent session.
  static String refreshToken(String role) =>
      '${authPrefix(role.isEmpty ? 'talent' : role)}/refresh';

  /// Auth actions without a session: a 401 there is a real error (e.g. wrong
  /// credentials), not an expired access token.
  static const publicAuthActions = [
    'login',
    'social/google/login',
    'register',
    'email-verification',
    'email-verification/send-otp',
    'password-reset/send-otp',
    'reset-password-verification',
    'reset-password',
  ];

  /// Whether [path] is a public auth action of any role.
  static bool isPublicAuthPath(String path) => [
    for (final role in const ['talent', 'client'])
      for (final action in publicAuthActions) '${authPrefix(role)}/$action',
  ].any(path.endsWith);

  static bool isGoogleLogin(String path) =>
      path.endsWith('/social/google/login') && path.contains('/auth/');
}
