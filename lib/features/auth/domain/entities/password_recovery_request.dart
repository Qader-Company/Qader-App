import 'account_role.dart';

/// In-memory destination for the password-recovery preview; never a session.
class PasswordRecoveryRequest {
  const PasswordRecoveryRequest({required this.email, required this.role});
  final String email;
  final AccountRole role;
}
