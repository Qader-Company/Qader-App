import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/profile_setup/data/repositories/api_profile_edit_repository.dart';
import 'package:qader/features/profile_setup/domain/entities/onboarding_progress.dart';
import 'package:qader/features/profile_setup/domain/repositories/professional_fields_repository.dart';
import 'package:qader/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:qader/features/profile_setup/presentation/cubit/profile_setup_payloads.dart';

/// Trimmed copy of a real `GET` / `PATCH /talent/profile` response (Apidog).
Map<String, dynamic> _profileResponse() => {
  'success': true,
  'message': 'api.updated',
  'data': {
    'id': 1,
    'sections': [
      {
        'key': 'personal-information',
        'visible_fields': [
          'professional_field_id',
          'full_name',
          'email',
          'phone_number',
          'gender',
          'cv',
        ],
        'required_fields': ['full_name', 'email', 'phone_number', 'gender'],
        'conditional_required_fields': <Object?>[],
        'data': {
          'professional_field': {'id': 1, 'name': 'Software Development'},
          'full_name': 'Demo Talent',
          'email': 'talent@qader.test',
          'phone_country_code': '+20',
          'phone_number': '1012345678',
          'gender': 'male',
          'cv': {'id': 2, 'file_name': 'Demo_Talent_CV.pdf'},
        },
      },
      {
        'key': 'skills-and-experiences',
        'visible_fields': ['professional_summary', 'years_of_experience'],
        'required_fields': ['years_of_experience'],
        'conditional_required_fields': [
          {
            'field': 'experiences',
            'required_when': {
              'field': 'years_of_experience',
              'operator': '>',
              'value': 0,
            },
          },
        ],
        'data': {
          'professional_summary':
              'Backend engineer experienced in building scalable APIs.',
          'years_of_experience': '5',
        },
      },
      {
        'key': 'work-preferences',
        'visible_fields': [
          'work_types',
          'work_modes',
          'willing_to_relocate',
          'notice_period_days',
          'current_salary',
          'expected_salary',
        ],
        'required_fields': ['work_types', 'work_modes'],
        'conditional_required_fields': <Object?>[],
        'data': {
          'work_types': ['full_time', 'part_time'],
          'work_modes': ['hybrid', 'remote'],
          'willing_to_relocate': true,
          'notice_period_days': '30',
          'current_salary': '15000.00',
          'current_currency': {
            'id': 1,
            'name': 'Egyptian Pound',
            'code': 'EGP',
          },
          'expected_salary_min': '20000.00',
          'expected_salary_max': '30000.00',
          'expected_currency': {
            'id': 1,
            'name': 'Egyptian Pound',
            'code': 'EGP',
          },
        },
      },
    ],
  },
};

class _Fields extends Fake implements ProfessionalFieldsRepository {}

class _Api extends Fake implements ApiConsumer {
  Object? getBody = _profileResponse();
  Object? patchBody = _profileResponse();
  Failure? patchFailure;
  final patches = <(String, Object?, String?)>[];

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    expect(path, '/talent/profile');
    return Right(fromJson(getBody));
  }

  @override
  Future<Either<Failure, T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic json) fromJson,
  }) async {
    patches.add((path, data, contentType));
    if (patchFailure case final failure?) return Left(failure);
    return Right(fromJson(patchBody));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profile sections become an editable snapshot on step 1', () {
    final progress = OnboardingProgress.fromProfile(_profileResponse());
    expect(progress.step, 1);
    expect(progress.completed, isFalse);
    expect(progress.steps.keys, OnboardingProgress.keys);
    expect(
      progress.steps['personal-information']!.data['full_name'],
      'Demo Talent',
    );
    expect(
      progress.steps['work-preferences']!.visible,
      contains('expected_salary'),
    );
    for (final invalid in [
      null,
      {'success': false},
      {
        'success': true,
        'data': {'id': 1},
      },
      {
        'success': true,
        'data': {'sections': <Object?>[]},
      },
    ]) {
      expect(
        () => OnboardingProgress.fromProfile(invalid),
        throwsFormatException,
      );
    }
  });

  test('repository patches one section as JSON and checks success', () async {
    final api = _Api();
    final repository = ApiProfileEditRepository(api);
    expect((await repository.load()).getOrThrow().step, 1);

    final saved = await repository.updateSection('work-preferences', {
      'notice_period_days': 14,
    });
    expect(saved.isSuccess, isTrue);
    final (path, body, contentType) = api.patches.single;
    expect(path, '/talent/profile');
    expect(body, {
      'work-preferences': {'notice_period_days': 14},
    });
    expect(contentType, 'application/json');

    api.patchBody = {'success': false};
    final rejected = await repository.updateSection('work-preferences', {});
    expect(rejected.getErrorOrThrow().message, 'profile_step_save_failed');

    api.patchFailure = const NetworkFailure(message: 'offline');
    final offline = await repository.updateSection('work-preferences', {});
    expect(offline.getErrorOrThrow(), isA<NetworkFailure>());

    api.getBody = {'success': true, 'data': null};
    final invalid = await repository.load();
    expect(invalid.getErrorOrThrow().message, 'profile_progress_failed');
  });

  test('edit mode prefills the form and saves through PATCH', () async {
    final api = _Api();
    final repository = ApiProfileEditRepository(api);
    final draft = ProfileSetupCubit(
      fieldsRepository: _Fields(),
      editRepository: repository,
    );
    addTearDown(draft.close);
    expect(draft.isEditing, isTrue);
    expect(await draft.restoreProgress(), isTrue);
    expect(draft.step, 1);
    expect(draft.text('name').text, 'Demo Talent');
    expect(draft.text('email').text, 'talent@qader.test');
    expect(draft.savedCv?['file_name'], 'Demo_Talent_CV.pdf');
    expect(draft.text('noticeDays').text, '30');
    expect(draft.selectedValues('work_types'), {'full_time', 'part_time'});

    // Lookups normally come from the master-data endpoints.
    draft.setLookups(
      options: {
        ProfileLookup.workTypes: const [
          ProfileLookupOption(value: 'full_time', label: 'Full Time'),
          ProfileLookupOption(value: 'part_time', label: 'Part Time'),
        ],
        ProfileLookup.workModes: const [
          ProfileLookupOption(value: 'hybrid', label: 'Hybrid'),
          ProfileLookupOption(value: 'remote', label: 'Remote'),
        ],
        ProfileLookup.currencies: const [
          ProfileLookupOption(value: 1, label: 'EGP'),
        ],
      },
    );
    draft.text('noticeDays').text = '14';
    draft.selectValues('work_types', {'full_time'});

    expect(await draft.saveDetails(work: true), isTrue);
    expect(draft.stepFailure, isNull);
    final (path, body, contentType) = api.patches.single;
    expect(path, '/talent/profile');
    expect(contentType, 'application/json');
    expect(body, {
      'work-preferences': {
        'work_types': ['full_time'],
        'work_modes': ['hybrid', 'remote'],
        'notice_period_days': 14,
        'willing_to_relocate': true,
        'current_salary': 15000.0,
        'current_currency_id': 1,
        'expected_salary_min': 20000.0,
        'expected_salary_max': 30000.0,
        'expected_currency_id': 1,
      },
    });

    api.patchFailure = const ServerFailure(message: 'The notice is invalid.');
    expect(await draft.saveDetails(work: true), isFalse);
    expect(draft.stepFailure?.message, 'The notice is invalid.');
  });

  test('experiences are required only when years of experience > 0', () async {
    final draft = ProfileSetupCubit(
      fieldsRepository: _Fields(),
      editRepository: ApiProfileEditRepository(_Api()),
    );
    addTearDown(draft.close);
    expect(await draft.restoreProgress(), isTrue);
    expect(draft.requiredWhen['experiences']?.whenField, 'years_of_experience');
    expect(draft.text('years').text, '5');
    expect(draft.requiresField('experiences'), isTrue);
    draft.text('years').text = '0';
    expect(draft.requiresField('experiences'), isFalse);
    draft.text('years').text = '';
    expect(draft.requiresField('experiences'), isTrue);

    draft.formFields = {'years_of_experience', 'experiences'};
    draft.setEntries(experiences: []);
    draft.text('years').text = '0';
    expect(draft.detailsPayload(work: false).values['experiences'], isEmpty);
    draft.text('years').text = '3';
    expect(() => draft.detailsPayload(work: false), throwsFormatException);
  });

  test('malformed conditional rules are skipped', () {
    final rules = RequiredWhen.parseAll([
      null,
      {'field': 'experiences'},
      {
        'field': 'experiences',
        'required_when': {'field': 'years', 'operator': '>', 'value': 'x'},
      },
      {
        'field': 'projects',
        'required_when': {'field': 'years', 'operator': '>=', 'value': '2'},
      },
    ]);
    expect(rules.single.field, 'projects');
    expect(rules.single.holds(2), isTrue);
    expect(rules.single.holds(1), isFalse);
    expect(RequiredWhen.parseAll('none'), isEmpty);
  });

  test('a cleared optional link is sent as null only when editing', () async {
    Future<Map<String, dynamic>> links(ProfileSetupCubit draft) async {
      draft.formFields = {'linkedin_url', 'github_url', 'behance_url'};
      draft.text('LinkedIn').text = 'https://linkedin.com/in/demo';
      draft.text('GitHub').text = '';
      draft.text('Behance').text = 'https://behance.net/demo';
      return draft.detailsPayload(work: false).values;
    }

    final editing = ProfileSetupCubit(
      fieldsRepository: _Fields(),
      editRepository: ApiProfileEditRepository(_Api()),
    );
    addTearDown(editing.close);
    expect(await links(editing), {
      'linkedin_url': 'https://linkedin.com/in/demo',
      'github_url': null,
      'behance_url': 'https://behance.net/demo',
    });

    final onboarding = ProfileSetupCubit(fieldsRepository: _Fields());
    addTearDown(onboarding.close);
    expect(await links(onboarding), {
      'linkedin_url': 'https://linkedin.com/in/demo',
      'behance_url': 'https://behance.net/demo',
    });
  });

  test(
    'a current job from the server is restored and sent without end date',
    () async {
      // From a real GET /talent/profile response (Apidog, 2026-11-18): the
      // job is current but the server still keeps the old end date.
      final response = _profileResponse();
      final sections = (response['data'] as Map)['sections'] as List;
      sections[1] = {
        'key': 'skills-and-experiences',
        'visible_fields': ['years_of_experience', 'experiences'],
        'required_fields': ['years_of_experience', 'experiences'],
        'conditional_required_fields': [
          {
            'field': 'experiences',
            'required_when': {
              'field': 'years_of_experience',
              'operator': '>',
              'value': 0,
            },
          },
        ],
        'data': {
          'years_of_experience': '5',
          'experiences': [
            {
              'id': 4,
              'job_title': 'Backend Engineer',
              'company_name': 'Qader',
              'company_url': 'https://qader.example.com',
              'started_at': '2022-01-01',
              'ended_at': '2023-01-01',
              'currently_working': true,
              'responsibilities':
                  'Designed APIs and maintained backend services. v',
              'display_order': '0',
            },
          ],
        },
      };
      final api = _Api()..getBody = response;
      final draft = ProfileSetupCubit(
        fieldsRepository: _Fields(),
        editRepository: ApiProfileEditRepository(api),
      );
      addTearDown(draft.close);
      expect(await draft.restoreProgress(), isTrue);
      final entry = draft.experiences.single;
      expect(entry.current, isTrue);
      expect(entry.to, isNull);
      expect(draft.text('experience_${entry.id}_to').text, isEmpty);
      expect(draft.requiresField('experiences'), isTrue);

      final experience =
          (draft.detailsPayload(work: false).values['experiences'] as List)
                  .single
              as Map;
      expect(experience['id'], 4);
      expect(experience['currently_working'], isTrue);
      expect(experience.containsKey('ended_at'), isTrue);
      expect(experience['ended_at'], isNull);

      // A finished job sends its end date.
      draft.updateExperience(
        entry.id,
        (e) => e.copyWith(current: false, to: DateTime(2024, 6, 30)),
      );
      final finished =
          (draft.detailsPayload(work: false).values['experiences'] as List)
                  .single
              as Map;
      expect(finished['ended_at'], '2024-06-30');
    },
  );
}
