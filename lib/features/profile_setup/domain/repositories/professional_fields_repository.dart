import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/professional_field.dart';

abstract class ProfessionalFieldsRepository {
  Future<Either<Failure, List<ProfessionalField>>> load();
  Future<Either<Failure, void>> select(int id);
  Future<Either<Failure, Set<String>>> formFields(int professionalFieldId);
}
