import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:qader/features/profile_setup/domain/entities/profile_cv.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/profile_setup/data/repositories/api_onboarding_steps_repository.dart';

class _Api extends Fake implements ApiConsumer {
  String? path;
  String? contentType;
  dynamic body;
  Object? response = {'success': true};
  Failure? failure;

  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic) fromJson,
  }) async {
    this.path = path;
    this.contentType = contentType;
    body = data;
    return failure == null ? Right(fromJson(response)) : Left(failure!);
  }
}

void main() {
  test(
    'personal multipart contains indexed languages, CV bytes and only visible fields',
    () async {
      final api = _Api();
      final repo = ApiOnboardingStepsRepository(api);
      final values = <String, dynamic>{
        'professional_field_id': 42,
        'full_name': 'Ahmed Hassan',
        'phone_country_code': '+20',
        'phone_number': '1012345678',
        'whatsapp_country_code': '+966',
        'whatsapp_number': '501234567',
        'gender': 'male',
        'religion': 'islam',
        'date_of_birth': '1995-05-20',
        'nationality_country_id': 7,
        'residence_country_id': 7,
        'residence_city_id': 22,
        'languages': [
          {'language_id': 9, 'proficiency_level': 'native'},
          {'language_id': 19, 'proficiency_level': 'b1'},
        ],
        'email': 'must-not-send@example.test',
        'job_title_id': 4,
      };
      final visible = values.keys.toSet()
        ..remove('religion')
        ..add('cv');
      const cv = ProfileCv(name: 'cv.pdf', bytes: [1, 2, 3, 4]);
      expect(
        (await repo.savePersonalInformation(
          values,
          visibleFields: visible,
          cv: cv,
        )).isSuccess,
        isTrue,
      );
      expect(api.path, '/talent/onboarding/personal-information');
      expect(api.contentType, isNull); // Dio generates the multipart boundary.
      final form = api.body as FormData;
      expect(Map.fromEntries(form.fields), {
        'professional_field_id': '42',
        'full_name': 'Ahmed Hassan',
        'phone_country_code': '+20',
        'phone_number': '1012345678',
        'whatsapp_country_code': '+966',
        'whatsapp_number': '501234567',
        'gender': 'male',
        'date_of_birth': '1995-05-20',
        'nationality_country_id': '7',
        'residence_country_id': '7',
        'residence_city_id': '22',
        'languages[0][language_id]': '9',
        'languages[0][proficiency_level]': 'native',
        'languages[1][language_id]': '19',
        'languages[1][proficiency_level]': 'b1',
      });
      expect(form.files.single.value.filename, 'cv.pdf');
      expect(
        await form.files.single.value
            .finalize()
            .expand((bytes) => bytes)
            .toList(),
        [1, 2, 3, 4],
      );
      await repo.savePersonalInformation(
        values,
        visibleFields: visible,
        cv: cv,
      );
      expect(identical(form, api.body), isFalse);
      expect((api.body as FormData).files.single.value.isFinalized, isFalse);
    },
  );

  test(
    'CV file paths work, unreadable files and bad language entries never POST',
    () async {
      final folder = await Directory.systemTemp.createTemp('qader_cv_test_');
      final file = File('${folder.path}/cv.pdf');
      addTearDown(() async {
        if (await file.exists()) await file.delete();
        await folder.delete();
      });
      await file.writeAsBytes(utf8.encode('%PDF-1.4'));
      final api = _Api();
      final repo = ApiOnboardingStepsRepository(api);
      expect(
        (await repo.savePersonalInformation(
          {'professional_field_id': 3},
          visibleFields: {'cv'},
          cv: ProfileCv(name: 'cv.pdf', path: file.path),
        )).isSuccess,
        isTrue,
      );
      api.path = null;
      expect(
        (await repo.savePersonalInformation(
          {},
          visibleFields: {'cv'},
          cv: ProfileCv(
            name: 'missing.pdf',
            path: '${folder.path}/missing.pdf',
          ),
        )).isError,
        isTrue,
      );
      expect(
        (await repo.savePersonalInformation({}, visibleFields: {'cv'})).isError,
        isTrue,
      );
      expect(
        (await repo.savePersonalInformation(
          {
            'languages': [
              {'language_id': '9'},
            ],
          },
          visibleFields: {'languages'},
        )).isError,
        isTrue,
      );
      expect(api.path, isNull);
    },
  );

  test(
    'skills multipart preserves API IDs, nested records, project files and only visible fields',
    () async {
      final api = _Api();
      final repository = ApiOnboardingStepsRepository(api);
      final values = <String, dynamic>{
        'professional_summary': 'Backend engineer',
        'job_title_id': 42,
        'seniority_level': 'mid_level',
        'years_of_experience': 0,
        'skill_ids': [8, 3],
        'industry_ids': [9],
        'tool_ids': [],
        'github_url': 'https://github.com/example',
        'behance_url': null,
        'experiences': [
          {
            'job_title': 'Engineer',
            'company_name': 'Qader',
            'company_url': 'https://example.test',
            'started_at': '2022-01-01',
            'ended_at': '2024-01-01',
            'currently_working': false,
            'responsibilities': 'Built APIs',
            'display_order': 1,
          },
        ],
        'projects': [
          {
            'name': 'Platform',
            'description': 'Talent registration',
            'url': 'https://example.test/project',
            'display_order': 1,
          },
        ],
        'full_name': 'Must not enter this step',
        'work_types': ['full_time'],
      };
      final result = await repository.saveSkillsAndExperiences(
        values,
        visibleFields: values.keys.toSet()..remove('professional_summary'),
        projectImages: {
          0: [
            const ProfileCv(name: 'project.png', bytes: [1, 2, 3]),
          ],
        },
      );
      expect(result.isSuccess, isTrue);
      expect(api.path, '/talent/onboarding/skills-and-experiences');
      expect(api.contentType, isNull);
      final form = api.body as FormData;
      final fields = Map.fromEntries(form.fields);
      expect(fields['job_title_id'], '42');
      expect(fields['skill_ids[0]'], '8');
      expect(fields['skill_ids[1]'], '3');
      expect(fields['industry_ids[0]'], '9');
      expect(fields['experiences[0][currently_working]'], '0');
      expect(fields['experiences[0][started_at]'], '2022-01-01');
      expect(fields['projects[0][name]'], 'Platform');
      expect(fields.keys, isNot(contains('professional_summary')));
      expect(fields.keys, isNot(contains('full_name')));
      expect(fields.keys, isNot(contains('work_types')));
      expect(form.files.single.key, 'projects[0][images][0]');
      expect(form.files.single.value.filename, 'project.png');
      expect(
        await form.files.single.value
            .finalize()
            .expand((chunk) => chunk)
            .toList(),
        [1, 2, 3],
      );
    },
  );

  test('salary visibility expands to POST amounts and currency IDs', () async {
    final api = _Api();
    final repository = ApiOnboardingStepsRepository(api);
    final values = <String, dynamic>{
      'work_types': ['full_time', 'part_time'],
      'work_modes': ['remote', 'hybrid'],
      'willing_to_relocate': false,
      'notice_period_days': 0,
      'current_salary': 15000,
      'current_currency_id': 4,
      'expected_salary_min': 20000,
      'expected_salary_max': 30000,
      'expected_currency_id': 6,
      'industry_ids': [9],
    };
    expect(
      (await repository.saveWorkPreferences(
        values,
        visibleFields: {
          'work_types',
          'work_modes',
          'willing_to_relocate',
          'notice_period_days',
          'current_salary',
          'expected_salary',
          'industry_ids',
        },
      )).isSuccess,
      isTrue,
    );
    expect(api.path, '/talent/onboarding/work-preferences');
    expect(api.body, Map.of(values)..remove('industry_ids'));
    await repository.saveWorkPreferences(values, visibleFields: {'work_modes'});
    expect(api.body, {
      'work_modes': ['remote', 'hybrid'],
    });
  });

  test(
    'server failures and invalid acknowledgements never become success',
    () async {
      final api = _Api();
      final repository = ApiOnboardingStepsRepository(api);
      const failure = ValidationFailure(
        message: 'invalid job',
        errors: ['invalid job'],
      );
      api.failure = failure;
      final result = await repository.saveSkillsAndExperiences(
        {},
        visibleFields: {},
      );
      expect(result.getErrorOrThrow(), same(failure));
      api.failure = null;
      for (final raw in [
        null,
        {},
        {'success': false},
      ]) {
        api.response = raw;
        expect(
          (await repository.saveWorkPreferences({}, visibleFields: {})).isError,
          isTrue,
        );
      }
    },
  );
}
