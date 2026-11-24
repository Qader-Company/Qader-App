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
import '../../domain/repositories/profile_edit_repository.dart';
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
part 'profile_lookups.dart';
part 'profile_setup_saving.dart';

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
    ProfileEditRepository? editRepository,
  }) : _fieldsRepository = fieldsRepository,
       _editRepository = editRepository,
       _lookupsRepository = lookupsRepository,
       _stepsRepository = stepsRepository,
       super(
         ProfileSetupState(
           fields: fieldsRepository == null ? ProfessionalField.values : [],
           field: fieldsRepository == null
               ? ProfessionalField.values.first
               : null,
         ),
       ) {
    _progressRepository = editRepository ?? progressRepository;
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
  }
  final ProfessionalFieldsRepository? _fieldsRepository;
  final ProfileLookupsRepository? _lookupsRepository;
  final OnboardingStepsRepository? _stepsRepository;
  OnboardingProgressRepository? _progressRepository;

  /// Set when editing a saved profile: the form loads from and saves to
  /// `/talent/profile` instead of the onboarding steps.
  final ProfileEditRepository? _editRepository;
  bool get isEditing => _editRepository != null;

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
  Set<String> get requiredFields => state.requiredFields;

  /// Conditional rules by field; they override [requiredFields].
  Map<String, RequiredWhen> get requiredWhen => state.requiredWhen;

  /// Replaces the required-field rules (empty until a schema is known).
  void _setRequired(Set<String> fields, Map<String, RequiredWhen> rules) =>
      _set(
        state.copyWith(
          requiredFields: Set.unmodifiable(fields),
          requiredWhen: Map.unmodifiable(rules),
        ),
      );

  bool requiresField(String key) {
    final rule = requiredWhen[key];
    if (rule == null) return requiredFields.contains(key);
    return rule.holds(_numberField(rule.whenField));
  }

  /// Current form value of a numeric backend field used by conditional
  /// rules; `null` when unknown, which keeps the field required.
  num? _numberField(String field) => switch (field) {
    'years_of_experience' => num.tryParse(text('years').text.trim()),
    'notice_period_days' => num.tryParse(text('noticeDays').text.trim()),
    _ => null,
  };

  int _parseRequest = 0;
  bool get busy => state.busy;
  final multiSelections = <String, Set<String>>{};
  Set<String> selectedValues(String key) => multiSelections[key] ?? const {};
  void selectValues(String key, Set<String> values) {
    multiSelections[key] = Set.of(values);
    refresh();
  }

  Map<ProfileLookup, List<ProfileLookupOption>> get lookupOptions =>
      state.lookupOptions;
  Set<ProfileLookup> get lookupLoading => state.lookupLoading;
  Map<ProfileLookup, Failure> get lookupFailures => state.lookupFailures;
  final _lookupRequests = <ProfileLookup, int>{};

  /// Emits new, unmodifiable lookup collections; `null` keeps one as is.
  void _setLookups({
    Map<ProfileLookup, List<ProfileLookupOption>>? options,
    Set<ProfileLookup>? loading,
    Map<ProfileLookup, Failure>? failures,
  }) => _set(
    state.copyWith(
      lookupOptions: options == null ? null : Map.unmodifiable(options),
      lookupLoading: loading == null ? null : Set.unmodifiable(loading),
      lookupFailures: failures == null ? null : Map.unmodifiable(failures),
    ),
  );

  /// Puts lists in place as if they had loaded (tests only).
  @visibleForTesting
  void setLookups({
    Map<ProfileLookup, List<ProfileLookupOption>>? options,
    Set<ProfileLookup>? loading,
  }) => _setLookups(
    options: options == null ? null : {...lookupOptions, ...options},
    loading: loading,
  );

  List<ProfileLookupOption> options(ProfileLookup lookup) =>
      lookupOptions[lookup] ?? const [];
  int? lookupId(ProfileLookup lookup, String? key) {
    for (final option in options(lookup)) {
      if (option.key == key) return option.id;
    }
    return null;
  }

  List<ProfessionalField> get fields => state.fields;
  set fields(List<ProfessionalField> value) =>
      _set(state.copyWith(fields: List.unmodifiable(value)));
  ProfessionalField? get _field => state.field;
  set _field(ProfessionalField? value) => _set(state.copyWith(field: value));
  ProfessionalField? get selectedField => _field;
  ProfessionalField get field => _field!;
  Set<String>? get formFields => state.formFields;
  set formFields(Set<String>? value) => _set(
    state.copyWith(formFields: value == null ? null : Set.unmodifiable(value)),
  );
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
        final previousId = _field?.id;
        fields = value;
        _field = value.where((item) => item.id == previousId).lastOrNull;
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
      formFields = schema.getOrThrow();
      _setRequired({}, {});
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
      _setRequired({}, {});
      final scoped = {
        for (final lookup in ProfileLookup.values)
          if (lookup.isFieldScoped) lookup,
      };
      for (final lookup in scoped) {
        _lookupRequests[lookup] = (_lookupRequests[lookup] ?? 0) + 1;
      }
      _setLookups(
        options: {...lookupOptions}
          ..removeWhere((lookup, _) => scoped.contains(lookup)),
        failures: {...lookupFailures}
          ..removeWhere((lookup, _) => scoped.contains(lookup)),
        loading: {...lookupLoading}..removeAll(scoped),
      );
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
