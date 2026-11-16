part of 'profile_setup_cubit.dart';

/// Saving a form step: to the onboarding endpoints during setup, or to
/// `PATCH /talent/profile` when editing a saved profile.
extension ProfileSetupSaving on ProfileSetupCubit {
  Future<bool> savePersonalInformation() async {
    if (busy || !isConnected || isClosed) return false;
    savingPersonalInfo = true;
    personalFailure = null;
    refresh();
    try {
      final repository = _stepsRepository;
      final edit = _editRepository;
      if ((repository == null && edit == null) ||
          _field?.id == null ||
          formFields == null) {
        throw const FormatException('profile_step_save_failed');
      }
      final values = personalInformationPayload();
      if (edit != null) {
        final result = await edit.updateSection(
          OnboardingProgress.keys[0],
          values,
        );
        if (isClosed) return false;
        personalFailure = result.isError ? result.getErrorOrThrow() : null;
        return result.isSuccess;
      }
      final file = cv;
      final result = await repository!.savePersonalInformation(
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
      final edit = _editRepository;
      if ((repository == null && edit == null) || formFields == null) {
        throw const FormatException('profile_step_save_failed');
      }
      final (:values, :images) = detailsPayload(work: work);
      final result = edit != null
          ? await edit.updateSection(
              OnboardingProgress.keys[work ? 2 : 1],
              values,
            )
          : work
          ? await repository!.saveWorkPreferences(
              values,
              visibleFields: formFields!,
            )
          : await repository!.saveSkillsAndExperiences(
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
}
