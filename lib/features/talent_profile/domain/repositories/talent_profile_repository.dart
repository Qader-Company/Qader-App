import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/talent_profile.dart';

/// The signed-in talent's own profile.
abstract class TalentProfileRepository {
  /// `GET /talent/profile`.
  Future<Either<Failure, TalentProfile>> load();
}
