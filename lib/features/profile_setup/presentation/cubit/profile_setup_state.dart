import '../../../../core/network/failure.dart';
import '../../domain/entities/onboarding_progress.dart';
import '../../domain/entities/professional_field.dart';
import '../../domain/entities/profile_lookup.dart';

const _keep = Object();

/// What the profile setup screens render from: the current step, what is
/// loading or saving, and the last failure of each operation.
///
/// It also holds the professional fields with the chosen one and the
/// form schema the backend sends for it, and the master-data lists (unmodifiable) with their loading
/// and failure state.
///
/// Form inputs (text controllers, selections, entries) live on the cubit as
/// form state; every change to them emits a new [revision].
class ProfileSetupState {
  const ProfileSetupState({
    this.step = 0,
    this.fieldsLoading = false,
    this.savingField = false,
    this.fieldFailure,
    this.progressLoading = false,
    this.progressPending = false,
    this.progressFailure,
    this.savingPersonalInfo = false,
    this.personalFailure,
    this.savingDetails = false,
    this.stepFailure,
    this.parsingCv = false,
    this.cvParseFailure,
    this.cvAutofilled = false,
    this.revision = 0,
    this.lookupOptions = const {},
    this.lookupLoading = const {},
    this.lookupFailures = const {},
    this.fields = const [],
    this.field,
    this.formFields,
    this.requiredFields = const {},
    this.requiredWhen = const {},
  });

  final int step;
  final bool fieldsLoading;
  final bool savingField;
  final Failure? fieldFailure;
  final bool progressLoading;
  final bool progressPending;
  final Failure? progressFailure;
  final bool savingPersonalInfo;
  final Failure? personalFailure;
  final bool savingDetails;
  final Failure? stepFailure;
  final bool parsingCv;
  final Failure? cvParseFailure;
  final bool cvAutofilled;

  /// Bumped whenever form inputs change so listeners rebuild.
  final int revision;

  /// Loaded options of each master-data list.
  final Map<ProfileLookup, List<ProfileLookupOption>> lookupOptions;

  /// Lists being loaded.
  final Set<ProfileLookup> lookupLoading;

  /// The last failure of each list that failed to load.
  final Map<ProfileLookup, Failure> lookupFailures;

  /// Professional fields the talent can choose from.
  final List<ProfessionalField> fields;

  /// The chosen professional field.
  final ProfessionalField? field;

  /// Backend fields of the chosen field's form; `null` until known.
  final Set<String>? formFields;

  /// Fields the backend requires.
  final Set<String> requiredFields;

  /// Conditional rules by field; they override [requiredFields].
  final Map<String, RequiredWhen> requiredWhen;

  bool get busy =>
      progressLoading ||
      savingField ||
      savingPersonalInfo ||
      savingDetails ||
      parsingCv;

  ProfileSetupState copyWith({
    int? step,
    bool? fieldsLoading,
    bool? savingField,
    Object? fieldFailure = _keep,
    bool? progressLoading,
    bool? progressPending,
    Object? progressFailure = _keep,
    bool? savingPersonalInfo,
    Object? personalFailure = _keep,
    bool? savingDetails,
    Object? stepFailure = _keep,
    bool? parsingCv,
    Object? cvParseFailure = _keep,
    bool? cvAutofilled,
    int? revision,
    Map<ProfileLookup, List<ProfileLookupOption>>? lookupOptions,
    Set<ProfileLookup>? lookupLoading,
    Map<ProfileLookup, Failure>? lookupFailures,
    List<ProfessionalField>? fields,
    Object? field = _keep,
    Object? formFields = _keep,
    Set<String>? requiredFields,
    Map<String, RequiredWhen>? requiredWhen,
  }) => ProfileSetupState(
    step: step ?? this.step,
    fieldsLoading: fieldsLoading ?? this.fieldsLoading,
    savingField: savingField ?? this.savingField,
    fieldFailure: identical(fieldFailure, _keep)
        ? this.fieldFailure
        : fieldFailure as Failure?,
    progressLoading: progressLoading ?? this.progressLoading,
    progressPending: progressPending ?? this.progressPending,
    progressFailure: identical(progressFailure, _keep)
        ? this.progressFailure
        : progressFailure as Failure?,
    savingPersonalInfo: savingPersonalInfo ?? this.savingPersonalInfo,
    personalFailure: identical(personalFailure, _keep)
        ? this.personalFailure
        : personalFailure as Failure?,
    savingDetails: savingDetails ?? this.savingDetails,
    stepFailure: identical(stepFailure, _keep)
        ? this.stepFailure
        : stepFailure as Failure?,
    parsingCv: parsingCv ?? this.parsingCv,
    cvParseFailure: identical(cvParseFailure, _keep)
        ? this.cvParseFailure
        : cvParseFailure as Failure?,
    cvAutofilled: cvAutofilled ?? this.cvAutofilled,
    revision: revision ?? this.revision,
    lookupOptions: lookupOptions ?? this.lookupOptions,
    lookupLoading: lookupLoading ?? this.lookupLoading,
    lookupFailures: lookupFailures ?? this.lookupFailures,
    fields: fields ?? this.fields,
    field: identical(field, _keep) ? this.field : field as ProfessionalField?,
    formFields: identical(formFields, _keep)
        ? this.formFields
        : formFields as Set<String>?,
    requiredFields: requiredFields ?? this.requiredFields,
    requiredWhen: requiredWhen ?? this.requiredWhen,
  );
}
