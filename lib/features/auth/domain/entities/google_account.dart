/// What the app gets back from Google's account picker, ready to hand to the
/// backend's social login.
class GoogleAccount {
  const GoogleAccount({required this.idToken, this.name});

  /// Google ID token (a JWT) the backend verifies.
  final String idToken;

  /// The account's display name, when Google shares it.
  final String? name;
}
