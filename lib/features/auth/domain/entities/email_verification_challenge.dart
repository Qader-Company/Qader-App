import 'account_role.dart';

/// Route-safe registration result. Credentials stay in secure storage.
class EmailVerificationChallenge {
  const EmailVerificationChallenge({
    required this.email,
    this.role = AccountRole.talent,
  });
  final String email;

  /// The role that registered, so verification uses the same auth prefix.
  final AccountRole role;
}
