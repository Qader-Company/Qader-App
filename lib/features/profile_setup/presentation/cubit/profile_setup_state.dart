import '../../../../core/network/failure.dart';
import '../../domain/entities/profile_lookup.dart';

const _keep = Object();

/// What the profile setup screens render from: the current step, what is
/// loading or saving, and the last failure of each operation.
///
/// It also holds the master-data lists (unmodifiable) with their loading
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
  );
}
