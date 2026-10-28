import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/professional_field.dart';
import '../../domain/repositories/professional_fields_repository.dart';

class ApiProfessionalFieldsRepository implements ProfessionalFieldsRepository {
  const ApiProfessionalFieldsRepository(this._api);
  final ApiConsumer _api;
  static const fieldsPath = '/talent/master-data/professional-fields';
  static const selectionPath = '/talent/onboarding/professional-field';
  static const formFieldsPath = '/talent/onboarding/form-fields';

  @override
  Future<Either<Failure, Set<String>>> formFields(
    int professionalFieldId,
  ) async {
    if (professionalFieldId <= 0) {
      return const Left(ServerFailure(message: 'profile_select_field'));
    }
    final result = await _api.get<Object?>(
      formFieldsPath,
      queryParameters: {'professional_field_id': professionalFieldId},
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map ||
        raw['success'] != true ||
        raw['data'] is! List ||
        (raw['data'] as List).any(
          (key) => key is! String || key.trim().isEmpty,
        )) {
      return const Left(ServerFailure(message: 'profile_form_fields_invalid'));
    }
    return Right(Set<String>.from(raw['data'] as List));
  }

  @override
  Future<Either<Failure, List<ProfessionalField>>> load() async {
    final result = await _api.get<Object?>(fieldsPath, fromJson: (raw) => raw);
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true || raw['data'] is! List) {
      return const Left(
        ServerFailure(message: 'profile_fields_invalid_response'),
      );
    }
    final fields = <ProfessionalField>[];
    final ids = <int>{};
    for (final item in raw['data'] as List) {
      if (item is! Map ||
          item['id'] is! int ||
          (item['id'] as int) <= 0 ||
          item['name'] is! String ||
          (item['name'] as String).trim().isEmpty ||
          item['description'] is! String ||
          item['slug'] is! String ||
          item['is_active'] is! bool ||
          !ids.add(item['id'] as int)) {
        return const Left(
          ServerFailure(message: 'profile_fields_invalid_response'),
        );
      }
      if (item['is_active'] == true) {
        fields.add(
          ProfessionalField(
            item['name'] as String,
            item['description'] as String,
            const [],
            id: item['id'] as int,
            slug: item['slug'] as String,
          ),
        );
      }
    }
    return Right(fields);
  }

  @override
  Future<Either<Failure, void>> select(int id) async {
    if (id <= 0) {
      return const Left(ServerFailure(message: 'profile_select_field'));
    }
    // ApiConsumer uses the current access token and existing API-key headers.
    final result = await _api.patch<Object?>(
      selectionPath,
      data: {'professional_field_id': id},
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true) {
      return const Left(ServerFailure(message: 'profile_field_save_failed'));
    }
    return const Right(null);
  }
}
