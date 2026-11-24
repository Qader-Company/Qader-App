part of 'profile_setup_cubit.dart';

/// Adding, changing and removing skills and the repeating entries.
/// Every change replaces the list with a new one and emits a state.
extension ProfileEntriesEditing on ProfileSetupCubit {
  void addLanguage() =>
      _setEntries(languages: [...languages, LanguageEntry(_nextId++)]);

  void addExperience() =>
      _setEntries(experiences: [...experiences, ExperienceEntry(_nextId++)]);

  void addProject() =>
      _setEntries(projects: [...projects, ProjectEntry(_nextId++)]);

  /// Replaces whole entry lists (tests only).
  @visibleForTesting
  void setEntries({
    List<LanguageEntry>? languages,
    List<ExperienceEntry>? experiences,
    List<ProjectEntry>? projects,
  }) => _setEntries(
    languages: languages,
    experiences: experiences,
    projects: projects,
  );

  /// Adds a free-text skill unless it is there already (any case).
  void addSkill(String skill) {
    if (skills.any((item) => item.toLowerCase() == skill.toLowerCase())) {
      return;
    }
    _setEntries(skills: [...skills, skill]);
  }

  void removeSkill(String skill) =>
      _setEntries(skills: [...skills]..remove(skill));

  void removeLanguage(int id) =>
      _setEntries(languages: [...languages]..removeWhere((e) => e.id == id));

  void updateLanguage(int id, LanguageEntry Function(LanguageEntry) change) =>
      _setEntries(
        languages: [for (final e in languages) e.id == id ? change(e) : e],
      );

  void removeExperience(int id) => _setEntries(
    experiences: [...experiences]..removeWhere((e) => e.id == id),
  );

  void updateExperience(
    int id,
    ExperienceEntry Function(ExperienceEntry) change,
  ) => _setEntries(
    experiences: [for (final e in experiences) e.id == id ? change(e) : e],
  );

  void removeProject(int id) =>
      _setEntries(projects: [...projects]..removeWhere((e) => e.id == id));

  void updateProject(int id, ProjectEntry Function(ProjectEntry) change) =>
      _setEntries(
        projects: [for (final e in projects) e.id == id ? change(e) : e],
      );
}
