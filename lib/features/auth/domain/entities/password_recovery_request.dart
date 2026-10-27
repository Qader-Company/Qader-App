import 'account_role.dart';

/// In-memory recovery email and role; contains no credentials or login session.
class PasswordRecoveryRequest {
  const PasswordRecoveryRequest({required this.email, required this.role});
  final String email;
  final AccountRole role;
}
