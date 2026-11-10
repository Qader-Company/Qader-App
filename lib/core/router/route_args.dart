/// Arguments passed between features through the router (`extra`).
/// Kept in core so features don't import each other for them.
library;

/// Name and email to prefill profile setup with after sign-in.
class ProfileSetupSeed {
  const ProfileSetupSeed({required this.name, required this.email});
  final String name;
  final String email;
}
