import '../../domain/entities/auth_user.dart';

class AuthResponse {
  static Map<String, dynamic> data(Object? response) {
    if (response is! Map ||
        response['success'] != true ||
        response['data'] is! Map) {
      throw const FormatException('Invalid authentication response');
    }
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  static AuthUser user(Map<String, dynamic> data) {
    final raw = data['user'];
    if (raw is! Map ||
        raw['id'] is! int ||
        raw['email'] is! String ||
        raw['first_name'] is! String ||
        raw['last_name'] is! String ||
        raw['is_active'] is! bool ||
        !raw.containsKey('email_verified_at')) {
      throw const FormatException('Invalid user response');
    }
    return AuthUser(
      id: raw['id'] as int,
      firstName: raw['first_name'] as String,
      lastName: raw['last_name'] as String,
      email: raw['email'] as String,
      isActive: raw['is_active'] as bool,
      isEmailVerified:
          raw['email_verified_at'] is String &&
          (raw['email_verified_at'] as String).isNotEmpty,
    );
  }

  static String token(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! Map ||
        value['token'] is! String ||
        (value['token'] as String).isEmpty) {
      throw FormatException('Invalid $key response');
    }
    return value['token'] as String;
  }
}
