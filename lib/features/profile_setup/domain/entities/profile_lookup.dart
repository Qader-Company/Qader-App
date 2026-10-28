enum ProfileLookup {
  genders,
  religions,
  countries,
  cities,
  languages,
  languageProficiencies,
  currencies,
  jobTitles,
  skills,
  tools,
  industries,
  seniorityLevels,
  workTypes,
  workModes;

  String get endpoint => switch (this) {
    languageProficiencies => 'language-proficiencies',
    jobTitles => 'job-titles',
    seniorityLevels => 'seniority-levels',
    workTypes => 'work-types',
    workModes => 'work-modes',
    _ => name,
  };
  bool get isEnum => {
    genders,
    religions,
    languageProficiencies,
    seniorityLevels,
    workTypes,
    workModes,
  }.contains(this);
  bool get isFieldScoped => {jobTitles, skills, tools}.contains(this);
}

class ProfileLookupOption {
  const ProfileLookupOption({required this.value, required this.label});
  final Object value;
  final String label;
  String get key => value.toString();
  int? get id => value is int ? value as int : null;
}
