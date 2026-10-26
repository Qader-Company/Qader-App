/// Route-safe registration result. Credentials stay in secure storage.
class EmailVerificationChallenge {
  const EmailVerificationChallenge({required this.email});
  final String email;
}
