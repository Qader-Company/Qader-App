import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/profile_lookup.dart';
import '../../domain/repositories/profile_lookups_repository.dart';

class ApiProfileLookupsRepository implements ProfileLookupsRepository {
  const ApiProfileLookupsRepository(this._api);
  final ApiConsumer _api;

  @override
  Future<Either<Failure, List<ProfileLookupOption>>> load(
    ProfileLookup lookup, {
    int? countryId,
    int? professionalFieldId,
    String? search,
  }) async {
    const invalid = ServerFailure(message: 'profile_lookup_invalid');
    if (lookup == ProfileLookup.cities &&
        (countryId == null || countryId <= 0)) {
      return const Left(invalid);
    }
    if (search != null && search.length > 100) return const Left(invalid);
    if (professionalFieldId != null && professionalFieldId <= 0) {
      return const Left(invalid);
    }
    final query = <String, dynamic>{
      if (lookup == ProfileLookup.cities) 'country_id': countryId,
      if (lookup.isFieldScoped && professionalFieldId != null)
        'professional_field_id': professionalFieldId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final endpoint = lookup.endpoint;
    final result = await _api.get<Object?>(
      '/talent/master-data/$endpoint',
      queryParameters: query.isEmpty ? null : query,
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true || raw['data'] is! List) {
      return const Left(invalid);
    }
    final enums = lookup.isEnum;
    final options = <ProfileLookupOption>[];
    final keys = <String>{};
    for (final item in raw['data'] as List) {
      if (item is! Map) return const Left(invalid);
      final rawValue = item[enums ? 'value' : 'id'];
      // Master data can encode the same ID as either 12 or "12".
      // Normalize before validation/deduplication and keep enum codes intact.
      final value = !enums && rawValue is String
          ? (RegExp(r'^[0-9]+$').hasMatch(rawValue)
                ? int.tryParse(rawValue)
                : null)
          : rawValue;
      final label = item[enums ? 'label' : 'name'];
      if ((enums
              ? value is! String || value.trim().isEmpty
              : value is! int || value <= 0) ||
          label is! String ||
          label.trim().isEmpty ||
          (item.containsKey('is_active') && item['is_active'] is! bool) ||
          !keys.add(value.toString())) {
        return const Left(invalid);
      }
      if (item['is_active'] == false) continue;
      final code = item['code'];
      options.add(
        ProfileLookupOption(
          value: value as Object,
          label:
              lookup == ProfileLookup.currencies &&
                  code is String &&
                  code.isNotEmpty
              ? '$code — $label'
              : label,
        ),
      );
    }
    return Right(List.unmodifiable(options));
  }
}
