import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/repositories/onboarding_steps_repository.dart';
import '../../domain/entities/profile_cv.dart';
import 'package:dio/dio.dart';

class ApiOnboardingStepsRepository implements OnboardingStepsRepository {
  const ApiOnboardingStepsRepository(this._api);
  final ApiConsumer _api;
  static const skillsPath = '/talent/onboarding/skills-and-experiences';
  static const personalPath = '/talent/onboarding/personal-information';
  static const workPath = '/talent/onboarding/work-preferences';
  static const _skillsKeys = {
    'professional_summary',
    'job_title_id',
    'seniority_level',
    'years_of_experience',
    'skill_ids',
    'industry_ids',
    'tool_ids',
    'linkedin_url',
    'github_url',
    'behance_url',
    'portfolio_url',
    'experiences',
    'projects',
  };
  static const _workKeys = {
    'work_types',
    'work_modes',
    'willing_to_relocate',
    'notice_period_days',
    'current_salary',
    'current_currency_id',
    'expected_salary_min',
    'expected_salary_max',
    'expected_currency_id',
  };

  @override
  Future<Either<Failure, void>> savePersonalInformation(
    Map<String, dynamic> values, {
    required Set<String> visibleFields,
    ProfileCv? cv,
  }) async {
    const keys = {
      'full_name',
      'phone_number',
      'whatsapp_number',
      'date_of_birth',
      'gender',
      'religion',
      'nationality_country_id',
      'residence_country_id',
      'residence_city_id',
    };
    final allowed = keys.intersection(visibleFields)
      ..add('professional_field_id');
    if (visibleFields.contains('phone_number')) {
      allowed.add('phone_country_code');
    }
    if (visibleFields.contains('whatsapp_number')) {
      allowed.add('whatsapp_country_code');
    }
    final form = FormData.fromMap({
      for (final key in allowed)
        if (values[key] != null) key: values[key],
    });
    if (visibleFields.contains('languages') && values['languages'] is List) {
      final languages = values['languages'] as List;
      for (var i = 0; i < languages.length; i++) {
        final language = languages[i];
        if (language is! Map ||
            language['language_id'] is! int ||
            (language['language_id'] as int) <= 0 ||
            language['proficiency_level'] is! String ||
            (language['proficiency_level'] as String).isEmpty) {
          return const Left(
            ServerFailure(message: 'profile_language_incomplete'),
          );
        }
        form.fields.addAll([
          MapEntry(
            'languages[$i][language_id]',
            language['language_id'].toString(),
          ),
          MapEntry(
            'languages[$i][proficiency_level]',
            language['proficiency_level'] as String,
          ),
        ]);
      }
    }
    if (visibleFields.contains('cv')) {
      if (cv == null) {
        return const Left(
          ServerFailure(message: 'profile_please_select_your_cv'),
        );
      }
      try {
        final file = cv.bytes != null && cv.bytes!.isNotEmpty
            ? MultipartFile.fromBytes(cv.bytes!, filename: cv.name)
            : cv.path != null && cv.path!.isNotEmpty
            ? await MultipartFile.fromFile(cv.path!, filename: cv.name)
            : null;
        if (file == null) {
          return const Left(ServerFailure(message: 'profile_cv_read_failed'));
        }
        form.files.add(MapEntry('cv', file));
      } on Object {
        return const Left(ServerFailure(message: 'profile_cv_read_failed'));
      }
    }
    // Dio sets the multipart boundary and uses the current access token/API key.
    final result = await _api.post<Object?>(
      personalPath,
      data: form,
      fromJson: (raw) => raw,
    );
    return _acknowledge(result);
  }

  @override
  Future<Either<Failure, void>> saveSkillsAndExperiences(
    Map<String, dynamic> values, {
    required Set<String> visibleFields,
    Map<int, List<ProfileCv>> projectImages = const {},
  }) async {
    final form = FormData();
    for (final key in _skillsKeys.intersection(visibleFields)) {
      _addMultipart(form, key, values[key]);
    }
    if (visibleFields.contains('projects')) {
      try {
        final projects = values['projects'] as List? ?? const [];
        for (final entry in projectImages.entries) {
          if (entry.key < 0 || entry.key >= projects.length) {
            throw const FormatException();
          }
          for (var i = 0; i < entry.value.length; i++) {
            final image = entry.value[i];
            final file = image.bytes != null && image.bytes!.isNotEmpty
                ? MultipartFile.fromBytes(image.bytes!, filename: image.name)
                : image.path != null && image.path!.isNotEmpty
                ? await MultipartFile.fromFile(
                    image.path!,
                    filename: image.name,
                  )
                : null;
            if (file == null || file.length > 5 * 1024 * 1024) {
              throw const FormatException();
            }
            form.files.add(
              MapEntry('projects[${entry.key}][images][$i]', file),
            );
          }
        }
      } on Object {
        return const Left(
          ServerFailure(message: 'profile_project_file_failed'),
        );
      }
    }
    final result = await _api.post<Object?>(
      skillsPath,
      data: form,
      fromJson: (raw) => raw,
    );
    return _acknowledge(result);
  }

  void _addMultipart(FormData form, String key, dynamic value) {
    if (value == null) return;
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        _addMultipart(form, '$key[$i]', value[i]);
      }
    } else if (value is Map) {
      for (final entry in value.entries) {
        _addMultipart(form, '$key[${entry.key}]', entry.value);
      }
    } else {
      form.fields.add(
        MapEntry(key, value is bool ? (value ? '1' : '0') : value.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveWorkPreferences(
    Map<String, dynamic> values, {
    required Set<String> visibleFields,
  }) {
    // form-fields uses group names; the POST contract splits salary amounts
    // and currencies into separate fields.
    final allowed = _workKeys.intersection(visibleFields);
    if (visibleFields.contains('current_salary')) {
      allowed.add('current_currency_id');
    }
    if (visibleFields.contains('expected_salary')) {
      allowed.addAll({
        'expected_salary_min',
        'expected_salary_max',
        'expected_currency_id',
      });
    }
    return _save(workPath, values, allowed);
  }

  Future<Either<Failure, void>> _save(
    String path,
    Map<String, dynamic> values,
    Set<String> allowed,
  ) async {
    final result = await _api.post<Object?>(
      path,
      data: {
        for (final key in allowed)
          if (values.containsKey(key) && values[key] != null) key: values[key],
      },
      contentType: 'application/json',
      fromJson: (raw) => raw,
    );
    return _acknowledge(result);
  }

  Either<Failure, void> _acknowledge(Either<Failure, Object?> result) {
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true) {
      return const Left(ServerFailure(message: 'profile_step_save_failed'));
    }
    return const Right(null);
  }
}
