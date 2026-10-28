import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/profile_lookup.dart';

abstract class ProfileLookupsRepository {
  Future<Either<Failure, List<ProfileLookupOption>>> load(
    ProfileLookup lookup, {
    int? countryId,
    int? professionalFieldId,
    String? search,
  });
}
