import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/profile_setup/data/repositories/api_onboarding_steps_repository.dart';
import 'package:qader/features/profile_setup/domain/entities/profile_cv.dart';
import 'package:qader/features/profile_setup/domain/repositories/professional_fields_repository.dart';
import 'package:qader/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';

class _Fields extends Fake implements ProfessionalFieldsRepository {}

/// Trimmed copy of the Apidog "Parse Resume for Autocomplete" response.
Map<String, dynamic> _parseResponse() => {
  'success': true,
  'message':
      'Resume parsed successfully. Review the suggested data before saving.',
  'data': {
    'cv': {
      'file_name': 'Ahmed_Abdelhaliem_Flutter_Developer.pdf',
      'mime_type': 'application/pdf',
      'size': 195733,
    },
    'suggestions': {
      'personal_information': {
        'full_name': 'Ahmed Abdelhaliem',
        'email': 'someone-else@example.test',
        'phone_country_code': '+20',
        'phone_number': '1065275078',
        'residence_country_id': 1,
        'residence_city_id': 1,
        'languages': [
          {'language_id': 1, 'proficiency_level': null},
          {'language_id': 2, 'proficiency_level': null},
        ],
      },
      'skills_and_experiences': {
        'professional_summary': 'Flutter Developer with production apps.',
        'years_of_experience': null,
        'job_title_id': null,
        'seniority_level': null,
        'linkedin_url': null,
        'github_url': 'https://github.com/ahmed',
        'skill_ids': [3, 4],
        'tool_ids': <int>[],
        'experiences': [
          {
            'job_title': 'Flutter Developer',
            'company_name': 'Qader',
            'company_url': null,
            'started_at': null,
            'ended_at': null,
            'currently_working': true,
            'responsibilities': 'Manage Android and iOS releases.',
            'display_order': 0,
          },
          {
            'job_title': 'Flutter Developer',
            'company_name': 'brmja Tech',
            'started_at': '2022-01-01',
            'ended_at': '2023-06-30',
            'currently_working': false,
            'responsibilities': 'Delivered 8+ apps.',
            'display_order': 1,
          },
        ],
        'projects': [
          {
            'name': 'Tharaa Al-Elm',
            'description': 'Learning management platform.',
            'url': 'Student App on Google Play | Teacher App on Google Play',
            'display_order': 0,
          },
          {
            'name': 'Raw Chem',
            'description': 'B2B marketplace.',
            'url': 'https://play.google.com/store/apps/details?id=rawchem',
            'display_order': 1,
          },
        ],
      },
    },
  },
};

class _Api extends Fake implements ApiConsumer {
  String? path;
  dynamic body;
  Object? response = _parseResponse();
  Failure? failure;

  /// Fail this many POSTs with a dropped connection first.
  int dropConnections = 0;
  int posts = 0;

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
    body = data;
    posts++;
    if (dropConnections > 0) {
      dropConnections--;
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
    return failure == null ? Right(fromJson(response)) : Left(failure!);
  }

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async => const Left(ServerFailure(message: 'not used'));
}

final _bytes = Uint8List.fromList([37, 80, 68]);

PlatformFile _cv() => PlatformFile(name: 'cv.pdf', size: 3, bytes: _bytes);

ProfileSetupCubit _draft(_Api api) => ProfileSetupCubit(
  fieldsRepository: _Fields(),
  stepsRepository: ApiOnboardingStepsRepository(api),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parse request uploads the CV as multipart "cv"', () async {
    final api = _Api();
    final result = await ApiOnboardingStepsRepository(
      api,
    ).parseResume(ProfileCv(name: 'cv.pdf', bytes: _bytes));
    expect(api.path, '/talent/onboarding/resume/parse');
    final form = api.body as FormData;
    expect(form.files.single.key, 'cv');
    expect(form.files.single.value.filename, 'cv.pdf');
    expect(result.getOrThrow().keys, {
      'personal_information',
      'skills_and_experiences',
    });
  });

  test('CV fills every step, replacing the signup name and email', () async {
    final api = _Api();
    final draft = _draft(api);
    addTearDown(draft.close);
    // Values restored from a previous save.
    draft.text('name').text = 'Old Name';
    draft.text('email').text = 'account@example.test';
    draft.text('phone').text = '1000000000';
    draft.selections['country'] = '7';
    draft.selections['city'] = '70';

    await draft.parseCv(_cv());

    expect(draft.parsingCv, isFalse);
    expect(draft.cvParseFailure, isNull);
    expect(draft.cvAutofilled, isTrue);
    // CV values replace single fields, including the signup email.
    expect(draft.text('name').text, 'Ahmed Abdelhaliem');
    expect(draft.text('email').text, 'someone-else@example.test');
    // Personal information.
    expect(draft.text('phoneCountryCode').text, '+20');
    expect(draft.text('phone').text, '1065275078');
    expect(draft.value('country'), '1');
    expect(draft.value('city'), '1');
    expect(draft.languages.map((entry) => entry.language), ['1', '2']);
    expect(draft.languages.every((entry) => entry.level == null), isTrue);
    // Skills & experience.
    expect(
      draft.text('summary').text,
      'Flutter Developer with production apps.',
    );
    expect(draft.text('GitHub').text, 'https://github.com/ahmed');
    expect(draft.selectedValues('skill_ids'), {'3', '4'});
    expect(draft.experiences, hasLength(2));
    final first = draft.experiences.first;
    expect(draft.text('experience_${first.id}_company').text, 'Qader');
    expect(first.current, isTrue);
    expect(first.from, isNull, reason: 'talent must add the start date');
    final second = draft.experiences.last;
    expect(second.from, DateTime(2022));
    expect(second.to, DateTime(2023, 6, 30));
    expect(draft.projects, hasLength(2));
    final tharaa = draft.projects.first;
    expect(draft.text('project_${tharaa.id}_name').text, 'Tharaa Al-Elm');
    expect(
      draft.text('project_${tharaa.id}_url').text,
      isEmpty,
      reason: 'store labels are not URLs',
    );
    expect(
      draft.text('project_${draft.projects.last.id}_url').text,
      'https://play.google.com/store/apps/details?id=rawchem',
    );
  });

  test('existing experiences and projects are kept', () async {
    final api = _Api();
    final draft = _draft(api);
    addTearDown(draft.close);
    draft.addExperience();
    final mine = draft.experiences.single;
    draft.text('experience_${mine.id}_company').text = 'My Company';

    await draft.parseCv(_cv());

    expect(draft.experiences.single, same(mine));
    expect(draft.text('experience_${mine.id}_company').text, 'My Company');
    expect(draft.projects, hasLength(2), reason: 'projects were empty');
  });

  test('a failed parse reports and changes nothing', () async {
    final api = _Api()
      ..failure = const ServerFailure(message: 'Could not parse');
    final draft = _draft(api);
    addTearDown(draft.close);

    await draft.parseCv(_cv());

    expect(draft.cvParseFailure?.message, 'Could not parse');
    expect(draft.cvAutofilled, isFalse);
    expect(draft.busy, isFalse);
    expect(draft.text('phone').text, isEmpty);
    expect(draft.experiences, isEmpty);
  });

  test('a dropped connection is retried with a fresh upload', () async {
    final api = _Api()..dropConnections = 2;
    final result = await ApiOnboardingStepsRepository(
      api,
    ).parseResume(ProfileCv(name: 'cv.pdf', bytes: _bytes));
    expect(result.isSuccess, isTrue);
    expect(api.posts, 3);
    expect((api.body as FormData).files.single.value.isFinalized, isFalse);
  });

  test('gives up after three dropped connections', () async {
    final api = _Api()..dropConnections = 5;
    final result = await ApiOnboardingStepsRepository(
      api,
    ).parseResume(ProfileCv(name: 'cv.pdf', bytes: _bytes));
    expect(result.getErrorOrThrow(), isA<NetworkFailure>());
    expect(api.posts, 3);
  });

  test('server errors are not retried', () async {
    final api = _Api()
      ..failure = const ServerFailure(message: 'Invalid file', statusCode: 422);
    await ApiOnboardingStepsRepository(
      api,
    ).parseResume(ProfileCv(name: 'cv.pdf', bytes: _bytes));
    expect(api.posts, 1);
  });
}
