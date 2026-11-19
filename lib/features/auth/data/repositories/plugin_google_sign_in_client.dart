import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/google_account.dart';
import '../../domain/repositories/google_sign_in_client.dart';

/// [GoogleSignInClient] backed by the google_sign_in plugin.
///
/// On Android the server client id is read from `google-services.json`
/// (`default_web_client_id`), so none is passed here.
class PluginGoogleSignInClient implements GoogleSignInClient {
  PluginGoogleSignInClient([GoogleSignIn? googleSignIn])
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  // The plugin must be initialized exactly once.
  Future<void>? _initialized;

  @override
  Future<Either<Failure, GoogleAccount?>> signIn() async {
    try {
      await (_initialized ??= _googleSignIn.initialize());
      if (!_googleSignIn.supportsAuthenticate()) {
        return const Left(ServerFailure(message: 'google_sign_in_failed'));
      }
      // Always show the picker so the user can choose another account.
      await _googleSignIn.signOut();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const Left(ServerFailure(message: 'google_sign_in_failed'));
      }
      return Right(GoogleAccount(idToken: idToken, name: account.displayName));
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const Right(null);
      }
      return const Left(ServerFailure(message: 'google_sign_in_failed'));
    }
  }
}
