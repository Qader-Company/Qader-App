import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/google_account.dart';

/// Shows Google's account picker. Kept behind an interface so the cubit and
/// tests never depend on the google_sign_in plugin.
abstract class GoogleSignInClient {
  /// The picked account, `Right(null)` when the user closed the picker, or a
  /// failure (misconfiguration, no network, no Google account support).
  Future<Either<Failure, GoogleAccount?>> signIn();
}
