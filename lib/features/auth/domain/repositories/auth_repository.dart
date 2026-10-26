import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> login(String email, String password);
  Future<Either<Failure, AuthUser>> currentUser();
  Future<Either<Failure, void>> logout();
}
