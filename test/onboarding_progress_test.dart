import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/profile_setup/domain/entities/onboarding_progress.dart';
import 'package:qader/features/profile_setup/data/repositories/api_onboarding_progress_repository.dart';
import 'package:qader/features/profile_setup/data/repositories/api_onboarding_steps_repository.dart';
import 'package:qader/features/profile_setup/domain/repositories/professional_fields_repository.dart';
import 'package:qader/features/profile_setup/presentation/profile_setup_controller.dart';
import 'fixtures/onboarding_progress_fixture.dart';

class _Fields extends Fake implements ProfessionalFieldsRepository {}

class _Api extends Fake implements ApiConsumer {
  dynamic response = progressResponse();
  Failure? failure;
  Completer<void>? gate;
  int reads = 0;
  int writes = 0;
  FormData? saved;
  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    expect(path, '/talent/onboarding');
    reads++;
    await gate?.future;
    return failure != null ? Left(failure!) : Right(fromJson(response));
  }

  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic) fromJson,
  }) async {
    writes++;
    saved = data as FormData;
    return Right(fromJson({'success': true}));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'server current step wins over completed later steps; no field starts selection',
    () {
      expect(OnboardingProgress.fromJson(progressResponse()).step, 2);
      expect(
        OnboardingProgress.fromJson(
          progressResponse(current: 'personal-information'),
        ).step,
        1,
      );
      expect(
        OnboardingProgress.fromJson(
          progressResponse(current: 'work-preferences'),
        ).step,
        3,
      );
      expect(
        OnboardingProgress.fromJson(progressResponse(hasField: false)).step,
        0,
      );
      expect(
        OnboardingProgress.fromJson(progressResponse(completed: true)).step,
        4,
      );
      expect(
        () => OnboardingProgress.fromJson(progressResponse(current: 'unknown')),
        throwsFormatException,
      );
    },
  );
  test(
    'hydrates all steps, nested IDs, enum values, files and string numbers',
    () async {
      final api = _Api();
      final draft = ProfileSetupController(
        fieldsRepository: _Fields(),
        progressRepository: ApiOnboardingProgressRepository(api),
      );
      addTearDown(draft.dispose);
      expect(await draft.restoreProgress(), isTrue);
      expect(draft.step, 2);
      expect(draft.selectedField!.id, 1);
      expect(draft.text('name').text, 'Demo Talent');
      expect(draft.text('phoneCountryCode').text, '+20');
      expect(draft.value('city'), '1');
      expect(draft.value('job'), isNull);
      expect(draft.value('level'), 'mid_level');
      expect(draft.text('years').text, '5');
      expect(draft.birthday, DateTime(1995, 5, 20));
      expect(draft.languages.single.language, '1');
      expect(draft.languages.single.level, 'a1');
      expect(draft.savedCv!['file_name'], 'saved-cv.pdf');
      expect(draft.cv, isNull);
      expect(draft.experiences.single.serverId, 4);
      expect(draft.experiences.single.from, DateTime(2022));
      expect(draft.projects.single.savedImages.single['id'], 9);
      expect(draft.selectedValues('tool_ids'), {'8'});
      expect(draft.selectedValues('work_types'), {'full_time', 'part_time'});
      expect(draft.value('relocate'), 'Yes');
      expect(draft.text('minSalary').text, '20000.00');
      expect(draft.requiresField('skill_ids'), isTrue);
      expect(draft.requiresField('tool_ids'), isFalse);
    },
  );
  test(
    'failed progress GET preserves draft, retry and disposal never POST',
    () async {
      final api = _Api()..failure = const NetworkFailure(message: 'offline');
      final draft = ProfileSetupController(
        fieldsRepository: _Fields(),
        progressRepository: ApiOnboardingProgressRepository(api),
      );
      draft.text('name').text = 'Unsaved draft';
      expect(await draft.restoreProgress(), isFalse);
      expect(draft.text('name').text, 'Unsaved draft');
      expect(draft.progressPending, isTrue);
      api.failure = null;
      api.gate = Completer<void>();
      final retry = draft.restoreProgress();
      expect(await draft.restoreProgress(), isFalse);
      api.gate!.complete();
      expect(await retry, isTrue);
      expect(draft.progressPending, isFalse);
      expect(api.writes, 0);
      api.gate = Completer<void>();
      final disposed = draft.restoreProgress();
      draft.dispose();
      api.gate!.complete();
      expect(await disposed, isFalse);
    },
  );
  test(
    'resume preserves server record IDs and existing media when saving',
    () async {
      final api = _Api();
      final draft = ProfileSetupController(
        fieldsRepository: _Fields(),
        progressRepository: ApiOnboardingProgressRepository(api),
        stepsRepository: ApiOnboardingStepsRepository(api),
      );
      addTearDown(draft.dispose);
      await draft.restoreProgress();
      for (final lookup in [
        ProfileLookup.jobTitles,
        ProfileLookup.skills,
        ProfileLookup.industries,
        ProfileLookup.tools,
        ProfileLookup.countries,
        ProfileLookup.cities,
        ProfileLookup.languages,
      ]) {
        draft.lookupOptions[lookup] = [
          const ProfileLookupOption(value: 1, label: 'One'),
          const ProfileLookupOption(value: 8, label: 'Eight'),
        ];
      }
      draft.lookupOptions[ProfileLookup.seniorityLevels] = [
        const ProfileLookupOption(value: 'mid_level', label: 'Mid'),
      ];
      draft.lookupOptions[ProfileLookup.genders] = [
        const ProfileLookupOption(value: 'male', label: 'Male'),
      ];
      draft.lookupOptions[ProfileLookup.religions] = [
        const ProfileLookupOption(value: 'islam', label: 'Islam'),
      ];
      draft.lookupOptions[ProfileLookup.languageProficiencies] = [
        const ProfileLookupOption(value: 'a1', label: 'A1'),
      ];
      expect(
        await draft.saveDetails(work: false),
        isFalse,
      ); // missing required IDs
      draft.select('job', '1');
      draft.selectValues('skill_ids', {'1'});
      draft.selectValues('industry_ids', {'1'});
      expect(await draft.saveDetails(work: false), isTrue);
      final values = Map.fromEntries(api.saved!.fields);
      expect(values['experiences[0][id]'], '4');
      expect(values['projects[0][id]'], '4');
      expect(
        values.keys.any((key) => key.contains('removed_image_ids')),
        isFalse,
      );
      expect(api.saved!.files, isEmpty);
      expect(await draft.savePersonalInformation(), isTrue);
      expect(
        api.saved!.files,
        isEmpty,
      ); // keep server CV; no fake file path or empty upload
      expect(
        Map.fromEntries(api.saved!.fields)['languages[0][proficiency_level]'],
        'a1',
      );
      api.response = progressResponse(completed: true);
      expect(await draft.restoreProgress(), isTrue);
      expect(draft.step, 4); // already completed work step is not forced again
    },
  );
  test(
    'malformed progress fails closed instead of assuming a new account',
    () async {
      final api = _Api()..response = {'success': true, 'data': {}};
      final repo = ApiOnboardingProgressRepository(api);
      expect((await repo.load()).isError, isTrue);
    },
  );
}
