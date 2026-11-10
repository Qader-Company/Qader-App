import '../../../../core/network/failure.dart';

const _keep = Object();

/// What the profile setup screens render from: the current step, what is
/// loading or saving, and the last failure of each operation.
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
  );
}
