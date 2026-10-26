import 'account_role.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isActive,
    required this.isEmailVerified,
  });
  final int id;
  final AccountRole role;
  final String firstName;
  final String lastName;
  final String email;
  final bool isActive;
  final bool isEmailVerified;
  String get fullName => '$firstName $lastName'.trim();
}
