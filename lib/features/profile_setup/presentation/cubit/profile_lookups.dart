part of 'profile_setup_cubit.dart';

/// Loading the master-data lists (countries, cities, languages, skills…)
/// that the steps need, with stale responses ignored.
extension ProfileLookups on ProfileSetupCubit {
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
}
