import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/auth_user.dart';
import '../entities/email_verification_challenge.dart';
import '../entities/registration_request.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> resendVerificationEmail(
    EmailVerificationChallenge challenge,
  );
  Future<Either<Failure, EmailVerificationChallenge>> register(
    RegistrationRequest request,
  );
  Future<Either<Failure, void>> verifyEmail(
    EmailVerificationChallenge challenge,
    String otp,
  );
  Future<Either<Failure, AuthUser>> login(String email, String password);

  /// Google sign-in: the backend verifies [idToken] and answers like
  /// [login].
  Future<Either<Failure, AuthUser>> googleLogin(String idToken, {String? name});
  Future<Either<Failure, AuthUser>> currentUser();
  Future<Either<Failure, void>> logout();
}
