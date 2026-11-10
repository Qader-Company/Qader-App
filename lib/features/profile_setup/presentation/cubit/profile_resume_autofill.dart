part of 'profile_setup_cubit.dart';

/// Autocomplete from the uploaded CV. Uploading a CV is an explicit request
/// to fill the form, so every value the CV provides replaces the current
/// single field, including the name and email shown from signup. Lists are
/// merged:
/// languages/skills are added, experiences/projects are filled only when the
/// talent has none yet, so saved entries are never dropped. The talent
/// reviews everything before each step is saved.
extension ProfileResumeAutofill on ProfileSetupCubit {
  Future<void> parseCv(PlatformFile file) async {
    final repository = _stepsRepository;
    if (repository == null || !isConnected || isClosed) return;
    final request = ++_parseRequest;
    parsingCv = true;
    cvParseFailure = null;
    cvAutofilled = false;
    refresh();
    try {
      final result = await repository.parseResume(
        ProfileCv(name: file.name, path: file.path, bytes: file.bytes),
      );
      if (isClosed || request != _parseRequest) return;
      if (result.isError) {
        cvParseFailure = result.getErrorOrThrow();
        return;
      }
      await applyResumeSuggestions(result.getOrThrow());
      if (!isClosed) cvAutofilled = true;
    } on Object {
      if (!isClosed && request == _parseRequest) {
        cvParseFailure = const ServerFailure(
          message: 'profile_cv_parse_failed',
        );
      }
    } finally {
      if (!isClosed && request == _parseRequest) {
        parsingCv = false;
        refresh();
      }
    }
  }

  /// Removing the CV drops a pending parse result.
  void cancelCvParse() {
    _parseRequest++;
    parsingCv = false;
    cvParseFailure = null;
    cvAutofilled = false;
    refresh();
  }

  Future<void> applyResumeSuggestions(Map<String, dynamic> suggestions) async {
    final personal = _asMap(suggestions['personal_information']);
    final skills = _asMap(suggestions['skills_and_experiences']);

    void fill(String key, Object? value) {
      final content = value?.toString().trim() ?? '';
      if (content.isNotEmpty) text(key).text = content;
    }

    void choose(String key, Object? value) {
      if (value != null) selections[key] = value.toString();
    }

    // Personal information: the CV replaces the signup name and email.
    fill('name', personal['full_name']);
    fill('email', personal['email']);
    if (personal['phone_number'] != null) {
      fill('phoneCountryCode', personal['phone_country_code']);
      fill('phone', personal['phone_number']);
    }
    choose('nationality', personal['nationality_country_id']);
    final countryId = personal['residence_country_id']?.toString();
    if (countryId != null && selections['country'] != countryId) {
      selections['country'] = countryId;
      selections.remove('city');
      if (showsField('residence_city_id')) {
        // Cities depend on the country; load them so the city can show.
        lookupOptions.remove(ProfileLookup.cities);
        await loadLookup(ProfileLookup.cities, retry: true);
        if (isClosed) return;
      }
    }
    if (countryId != null && selections['country'] == countryId) {
      choose('city', personal['residence_city_id']);
    }
    final known = {
      for (final entry in languages)
        if (entry.language != null) entry.language,
    };
    final suggested = [
      for (final item in personal['languages'] as List? ?? const [])
        if (item is Map && item['language_id'] != null)
          (
            id: item['language_id'].toString(),
            level: item['proficiency_level']?.toString(),
          ),
    ].where((item) => !known.contains(item.id)).toList();
    if (suggested.isNotEmpty) {
      languages.removeWhere(
        (entry) => entry.language == null && entry.level == null,
      );
      for (final item in suggested) {
        languages.add(
          LanguageEntry(_nextId++, language: item.id, level: item.level),
        );
      }
    }

    // Skills & experience step.
    fill('summary', skills['professional_summary']);
    fill('years', skills['years_of_experience']);
    choose('job', skills['job_title_id']);
    choose('level', skills['seniority_level']);
    for (final entry in {
      'linkedin_url': 'LinkedIn',
      'github_url': 'GitHub',
      'behance_url': 'Behance',
      'portfolio_url': 'Portfolio',
    }.entries) {
      final url = skills[entry.key];
      if (_isWebUrl(url)) fill(entry.value, url);
    }
    for (final key in ['skill_ids', 'tool_ids', 'industry_ids']) {
      final ids = [
        for (final id in skills[key] as List? ?? const [])
          if (id != null) id.toString(),
      ];
      if (ids.isNotEmpty) {
        multiSelections[key] = {...selectedValues(key), ...ids};
      }
    }
    final suggestedExperiences = skills['experiences'] as List? ?? const [];
    if (suggestedExperiences.isNotEmpty &&
        experiences.every(_emptyExperience)) {
      experiences.clear();
      for (final item in suggestedExperiences.whereType<Map>()) {
        final entry = ExperienceEntry(_nextId++)
          ..current = item['currently_working'] == true
          ..from = DateTime.tryParse(item['started_at']?.toString() ?? '')
          ..to = DateTime.tryParse(item['ended_at']?.toString() ?? '');
        experiences.add(entry);
        final prefix = 'experience_${entry.id}_';
        fill('${prefix}job', item['job_title']);
        fill('${prefix}company', item['company_name']);
        if (_isWebUrl(item['company_url'])) {
          fill('${prefix}url', item['company_url']);
        }
        fill('${prefix}from', item['started_at']);
        fill('${prefix}to', item['ended_at']);
        fill('${prefix}description', item['responsibilities']);
      }
    }
    final suggestedProjects = skills['projects'] as List? ?? const [];
    if (suggestedProjects.isNotEmpty && projects.every(_emptyProject)) {
      projects.clear();
      for (final item in suggestedProjects.whereType<Map>()) {
        final entry = ProjectEntry(_nextId++);
        projects.add(entry);
        final prefix = 'project_${entry.id}_';
        fill('${prefix}name', item['name']);
        fill('${prefix}description', item['description']);
        // Parsers may return labels like "Google Play"; keep only real links.
        if (_isWebUrl(item['url'])) fill('${prefix}url', item['url']);
      }
    }
    refresh();
  }

  bool _emptyExperience(ExperienceEntry entry) =>
      entry.serverId == null &&
      entry.from == null &&
      ['job', 'company', 'description'].every(
        (field) => text('experience_${entry.id}_$field').text.trim().isEmpty,
      );

  bool _emptyProject(ProjectEntry entry) =>
      entry.serverId == null &&
      entry.images.isEmpty &&
      entry.savedImages.isEmpty &&
      ['name', 'description'].every(
        (field) => text('project_${entry.id}_$field').text.trim().isEmpty,
      );
}

Map<String, dynamic> _asMap(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : const {};

bool _isWebUrl(Object? raw) {
  final uri = Uri.tryParse(raw?.toString().trim() ?? '');
  return uri != null &&
      {'http', 'https'}.contains(uri.scheme) &&
      uri.host.isNotEmpty;
}
