import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/auth_user.dart';
import '../entities/email_verification_challenge.dart';
import '../entities/registration_request.dart';

abstract class AuthRepository {
  Future<Either<Failure, EmailVerificationChallenge>> register(
    RegistrationRequest request,
  );
  Future<Either<Failure, void>> verifyEmail(
    EmailVerificationChallenge challenge,
    String otp,
  );
  Future<Either<Failure, AuthUser>> login(String email, String password);
  Future<Either<Failure, AuthUser>> currentUser();
  Future<Either<Failure, void>> logout();
}
