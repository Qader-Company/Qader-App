import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/network/either.dart';
import '../../domain/entities/professional_field.dart';
import '../../domain/repositories/professional_fields_repository.dart';
import '../../domain/repositories/profile_lookups_repository.dart';
import '../../domain/entities/profile_lookup.dart';
import '../../domain/entities/profile_cv.dart';
import '../../domain/repositories/onboarding_steps_repository.dart';
import '../../domain/repositories/onboarding_progress_repository.dart';
import '../../domain/entities/onboarding_progress.dart';
import '../preview/profile_setup_preview_data.dart';
import '../../../../core/router/route_args.dart';
export '../../../../core/router/route_args.dart';
export '../../domain/entities/profile_lookup.dart';
export '../../domain/entities/professional_field.dart';
import 'profile_setup_payloads.dart';
import 'profile_setup_state.dart';
export 'profile_setup_state.dart';

part 'profile_progress_restore.dart';
part 'profile_resume_autofill.dart';

class LanguageEntry {
  LanguageEntry(this.id, {this.language, this.level});
  final int id;
  String? language;
  String? level;
}

class ExperienceEntry {
  ExperienceEntry(this.id);
  final int id;
  int? serverId;
  bool current = false;
  DateTime? from;
  DateTime? to;
}

class ProjectEntry {
  ProjectEntry(this.id);
  final int id;
  int? serverId;
  final savedImages = <Map<String, dynamic>>[];
  final images = <PlatformFile>[];
}

/// Profile setup (onboarding) state. Field selection and every step persist
/// through the onboarding APIs; [ProfileSetupState] holds the step, loading
/// flags and failures, while form inputs are kept on the cubit.
class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit({
    ProfileSetupSeed? seed,
    ProfessionalFieldsRepository? fieldsRepository,
    ProfileLookupsRepository? lookupsRepository,
    OnboardingStepsRepository? stepsRepository,
    OnboardingProgressRepository? progressRepository,
  }) : _fieldsRepository = fieldsRepository,
       _lookupsRepository = lookupsRepository,
       _stepsRepository = stepsRepository,
       super(const ProfileSetupState()) {
    _progressRepository = progressRepository;
    text('name').text =
        seed?.name ??
        (fieldsRepository == null ? ProfileSetupPreviewData.name : '');
    text('email').text =
        seed?.email ??
        (fieldsRepository == null ? ProfileSetupPreviewData.email : '');
    if (fieldsRepository != null) {
      skills.clear();
      experiences.clear();
      projects.clear();
      languages
        ..clear()
        ..add(LanguageEntry(1));
    }
    fields = fieldsRepository == null ? ProfessionalField.values : [];
    _field = fieldsRepository == null ? fields.first : null;
  }
  final ProfessionalFieldsRepository? _fieldsRepository;
  final ProfileLookupsRepository? _lookupsRepository;
  final OnboardingStepsRepository? _stepsRepository;
  OnboardingProgressRepository? _progressRepository;

  // ─── State (see [ProfileSetupState]) ───
  bool get progressLoading => state.progressLoading;
  set progressLoading(bool value) =>
      _set(state.copyWith(progressLoading: value));
  Failure? get progressFailure => state.progressFailure;
  set progressFailure(Failure? value) =>
      _set(state.copyWith(progressFailure: value));
  bool get progressPending => state.progressPending;
  set progressPending(bool value) =>
      _set(state.copyWith(progressPending: value));
  bool get savingPersonalInfo => state.savingPersonalInfo;
  set savingPersonalInfo(bool value) =>
      _set(state.copyWith(savingPersonalInfo: value));
  bool get savingDetails => state.savingDetails;
  set savingDetails(bool value) => _set(state.copyWith(savingDetails: value));
  bool get parsingCv => state.parsingCv;
  set parsingCv(bool value) => _set(state.copyWith(parsingCv: value));
  Failure? get cvParseFailure => state.cvParseFailure;
  set cvParseFailure(Failure? value) =>
      _set(state.copyWith(cvParseFailure: value));
  bool get cvAutofilled => state.cvAutofilled;
  set cvAutofilled(bool value) => _set(state.copyWith(cvAutofilled: value));
  Failure? get stepFailure => state.stepFailure;
  set stepFailure(Failure? value) => _set(state.copyWith(stepFailure: value));
  Failure? get personalFailure => state.personalFailure;
  set personalFailure(Failure? value) =>
      _set(state.copyWith(personalFailure: value));
  bool get fieldsLoading => state.fieldsLoading;
  set fieldsLoading(bool value) => _set(state.copyWith(fieldsLoading: value));
  bool get savingField => state.savingField;
  set savingField(bool value) => _set(state.copyWith(savingField: value));
  Failure? get fieldFailure => state.fieldFailure;
  set fieldFailure(Failure? value) => _set(state.copyWith(fieldFailure: value));
  int get step => state.step;
  set step(int value) => _set(state.copyWith(step: value));

  void _set(ProfileSetupState next) {
    if (!isClosed) emit(next);
  }

  /// Form inputs changed: rebuild listeners.
  void refresh() => _set(state.copyWith(revision: state.revision + 1));
  Map<String, dynamic>? savedCv;
  final requiredFields = <String>{};
  bool requiresField(String key) => requiredFields.contains(key);

  int _parseRequest = 0;
  bool get busy => state.busy;
  final multiSelections = <String, Set<String>>{};
  Set<String> selectedValues(String key) => multiSelections[key] ?? const {};
  void selectValues(String key, Set<String> values) {
    multiSelections[key] = Set.of(values);
    refresh();
  }

  Future<bool> savePersonalInformation() async {
    if (busy || !isConnected || isClosed) return false;
    savingPersonalInfo = true;
    personalFailure = null;
    refresh();
    try {
      final repository = _stepsRepository;
      if (repository == null || _field?.id == null || formFields == null) {
        throw const FormatException('profile_step_save_failed');
      }
      final values = personalInformationPayload();
      final file = cv;
      final result = await repository.savePersonalInformation(
        values,
        visibleFields: {...formFields!}
          ..removeAll(file == null && savedCv != null ? {'cv'} : <String>{}),
        cv: file == null
            ? null
            : ProfileCv(name: file.name, path: file.path, bytes: file.bytes),
      );
      if (isClosed) return false;
      personalFailure = result.isError ? result.getErrorOrThrow() : null;
      return result.isSuccess;
    } on FormatException catch (error) {
      if (!isClosed) personalFailure = ServerFailure(message: error.message);
      return false;
    } on Object {
      if (!isClosed) {
        personalFailure = const ServerFailure(
          message: 'profile_step_save_failed',
        );
      }
      return false;
    } finally {
      if (!isClosed) {
        savingPersonalInfo = false;
        refresh();
      }
    }
  }

  Future<bool> saveDetails({required bool work}) async {
    if (busy || !isConnected || isClosed) return false;
    savingDetails = true;
    stepFailure = null;
    refresh();
    try {
      final repository = _stepsRepository;
      if (repository == null || formFields == null) {
        throw const FormatException('profile_step_save_failed');
      }
      final (:values, :images) = detailsPayload(work: work);
      final result = work
          ? await repository.saveWorkPreferences(
              values,
              visibleFields: formFields!,
            )
          : await repository.saveSkillsAndExperiences(
              values,
              visibleFields: formFields!,
              projectImages: images,
            );
      if (isClosed) return false;
      stepFailure = result.isError ? result.getErrorOrThrow() : null;
      return result.isSuccess;
    } on FormatException catch (error) {
      if (!isClosed) stepFailure = ServerFailure(message: error.message);
      return false;
    } on Object {
      if (!isClosed) {
        stepFailure = const ServerFailure(message: 'profile_step_save_failed');
      }
      return false;
    } finally {
      if (!isClosed) {
        savingDetails = false;
        refresh();
      }
    }
  }

  final lookupOptions = <ProfileLookup, List<ProfileLookupOption>>{};
  final lookupLoading = <ProfileLookup>{};
  final lookupFailures = <ProfileLookup, Failure>{};
  final _lookupRequests = <ProfileLookup, int>{};

  List<ProfileLookupOption> options(ProfileLookup lookup) =>
      lookupOptions[lookup] ?? const [];
  int? lookupId(ProfileLookup lookup, String? key) {
    for (final option in options(lookup)) {
      if (option.key == key) return option.id;
    }
    return null;
  }

  Future<void> loadRelevantLookups() async {
    final required = <ProfileLookup>{
      if (showsField('gender')) ProfileLookup.genders,
      if (showsField('religion')) ProfileLookup.religions,
      if (showsField('nationality_country_id') ||
          showsField('residence_country_id') ||
          showsField('residence_city_id'))
        ProfileLookup.countries,
      if (showsField('languages')) ProfileLookup.languages,
      if (showsField('languages')) ProfileLookup.languageProficiencies,
      if (showsField('expected_salary') || showsField('current_salary'))
        ProfileLookup.currencies,
      if (showsField('job_title_id')) ProfileLookup.jobTitles,
      if (showsField('skill_ids')) ProfileLookup.skills,
      if (showsField('tool_ids')) ProfileLookup.tools,
      if (showsField('industry_ids')) ProfileLookup.industries,
      if (showsField('seniority_level')) ProfileLookup.seniorityLevels,
      if (showsField('work_types')) ProfileLookup.workTypes,
      if (showsField('work_modes')) ProfileLookup.workModes,
    };
    await Future.wait(required.map((lookup) => loadLookup(lookup)));
  }

  Future<void> loadLookup(ProfileLookup lookup, {bool retry = false}) async {
    if (_lookupsRepository == null || isClosed) return;
    if (!retry &&
        (lookupLoading.contains(lookup) || lookupOptions.containsKey(lookup))) {
      return;
    }
    final countryId = lookupId(ProfileLookup.countries, value('country'));
    if (lookup == ProfileLookup.cities && countryId == null) return;
    if (lookup.isFieldScoped && _field?.id == null) return;
    final request = (_lookupRequests[lookup] ?? 0) + 1;
    _lookupRequests[lookup] = request;
    lookupLoading.add(lookup);
    lookupFailures.remove(lookup);
    refresh();
    try {
      final result = await _lookupsRepository.load(
        lookup,
        countryId: countryId,
        professionalFieldId: lookup.isFieldScoped ? _field?.id : null,
      );
      if (isClosed || _lookupRequests[lookup] != request) return;
      result.fold(
        (failure) => lookupFailures[lookup] = failure,
        (items) => lookupOptions[lookup] = items,
      );
    } on Object {
      if (!isClosed && _lookupRequests[lookup] == request) {
        lookupFailures[lookup] = const ServerFailure(
          message: 'profile_lookup_invalid',
        );
      }
    } finally {
      if (!isClosed && _lookupRequests[lookup] == request) {
        lookupLoading.remove(lookup);
        refresh();
      }
    }
  }

  Future<void> selectResidenceCountry(String? key) async {
    if (key == value('country')) return;
    if (key != null && lookupId(ProfileLookup.countries, key) == null) return;
    selections['country'] = key;
    selections.remove('city');
    _lookupRequests[ProfileLookup.cities] =
        (_lookupRequests[ProfileLookup.cities] ?? 0) + 1;
    lookupOptions.remove(ProfileLookup.cities);
    lookupFailures.remove(ProfileLookup.cities);
    lookupLoading.remove(ProfileLookup.cities);
    refresh();
    if (showsField('residence_city_id')) await loadLookup(ProfileLookup.cities);
  }

  late List<ProfessionalField> fields;
  ProfessionalField? _field;
  ProfessionalField? get selectedField => _field;
  ProfessionalField get field => _field!;
  Set<String>? formFields;
  bool get isConnected => _fieldsRepository != null;
  bool showsField(String key) =>
      !isConnected || (formFields?.contains(key) ?? false);

  Future<void> loadFields() async {
    if (_fieldsRepository == null || fieldsLoading || busy) return;
    fieldsLoading = true;
    fieldFailure = null;
    refresh();
    try {
      final result = await _fieldsRepository.load();
      if (isClosed) return;
      result.fold((failure) => fieldFailure = failure, (value) {
        fields = value;
        final previousId = _field?.id;
        _field = null;
        for (final candidate in fields) {
          if (candidate.id == previousId) _field = candidate;
        }
      });
    } on Object {
      if (!isClosed) {
        fieldFailure = const ServerFailure(
          message: 'profile_fields_load_failed',
        );
      }
    } finally {
      if (!isClosed) {
        fieldsLoading = false;
        refresh();
      }
    }
  }

  Future<bool> saveProfessionalField() async {
    if (fieldsLoading || busy || _field == null) return false;
    if (_fieldsRepository == null) return true;
    final id = _field!.id;
    if (id == null || !fields.contains(_field)) return false;
    savingField = true;
    fieldFailure = null;
    refresh();
    try {
      final result = await _fieldsRepository.select(id);
      if (isClosed) return false;
      fieldFailure = result.isError ? result.getErrorOrThrow() : null;
      if (result.isError) return false;
      final schema = await _fieldsRepository.formFields(id);
      if (isClosed) return false;
      if (schema.isError) {
        fieldFailure = schema.getErrorOrThrow();
        return false;
      }
      formFields = Set.unmodifiable(schema.getOrThrow());
      requiredFields.clear();
      return true;
    } on Object {
      if (!isClosed) {
        fieldFailure = const ServerFailure(
          message: 'profile_field_save_failed',
        );
      }
      return false;
    } finally {
      if (!isClosed) {
        savingField = false;
        refresh();
      }
    }
  }

  int _nextId = 3;
  final _text = <String, TextEditingController>{};
  final selections = <String, String?>{};
  final skills = [...ProfileSetupPreviewData.skills];
  final languages = [
    LanguageEntry(
      1,
      language: ProfileSetupPreviewData.language,
      level: ProfileSetupPreviewData.languageLevel,
    ),
    LanguageEntry(2),
  ];
  final experiences = [ExperienceEntry(1)];
  final projects = [ProjectEntry(1)];
  PlatformFile? cv;
  DateTime? birthday;
  TextEditingController text(String key) =>
      _text.putIfAbsent(key, TextEditingController.new);
  String? value(String key) => selections[key];
  void select(String key, String? value) {
    selections[key] = value;
    refresh();
  }

  void go(int value) {
    stepFailure = null;
    step = value;
    refresh();
  }

  void chooseField(ProfessionalField value) {
    if (busy || fieldsLoading || !fields.contains(value)) return;
    if (_field != value) {
      selections.remove('job');
      formFields = null;
      requiredFields.clear();
      for (final lookup in ProfileLookup.values.where(
        (item) => item.isFieldScoped,
      )) {
        _lookupRequests[lookup] = (_lookupRequests[lookup] ?? 0) + 1;
        lookupOptions.remove(lookup);
        lookupFailures.remove(lookup);
        lookupLoading.remove(lookup);
      }
      multiSelections.remove('skill_ids');
      multiSelections.remove('tool_ids');
    }
    _field = value;
    fieldFailure = null;
    refresh();
  }

  void addLanguage() {
    languages.add(LanguageEntry(_nextId++));
    refresh();
  }

  void addExperience() {
    experiences.add(ExperienceEntry(_nextId++));
    refresh();
  }

  void addProject() {
    projects.add(ProjectEntry(_nextId++));
    refresh();
  }

  @override
  Future<void> close() {
    for (final value in _text.values) {
      value.dispose();
    }
    return super.close();
  }
}
