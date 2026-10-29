part of 'profile_setup_controller.dart';

extension ProfileProgressRestore on ProfileSetupController {
  bool get hasProgressRepository => _progressRepository != null;

  /// Also used after each save, so a previously completed later step is skipped.
  /// Failure retains the draft and retry only repeats GET, never the successful POST.
  Future<bool> restoreProgress() async {
    if (_progressRepository == null || busy || _disposed) return false;
    progressLoading = true;
    progressPending = true;
    progressFailure = null;
    refresh();
    try {
      final result = await _progressRepository!.load();
      if (_disposed) return false;
      if (result.isError) {
        progressFailure = result.getErrorOrThrow();
        return false;
      }
      applyProgress(result.getOrThrow());
      progressPending = false;
      return true;
    } on Object {
      if (!_disposed) {
        progressFailure = const ServerFailure(
          message: 'profile_progress_failed',
        );
      }
      return false;
    } finally {
      if (!_disposed) {
        progressLoading = false;
        refresh();
      }
    }
  }

  void applyProgress(OnboardingProgress progress) {
    if (_disposed) return;
    // Invalidate earlier lookup responses before restoring another server snapshot.
    for (final lookup in ProfileLookup.values) {
      _lookupRequests[lookup] = (_lookupRequests[lookup] ?? 0) + 1;
    }
    lookupOptions.clear();
    lookupLoading.clear();
    lookupFailures.clear();
    selections.clear();
    multiSelections.clear();
    final seedName = text('name').text;
    final seedEmail = text('email').text;
    for (final controller in _text.values) {
      controller.clear();
    }
    formFields = {for (final item in progress.steps.values) ...item.visible};
    requiredFields
      ..clear()
      ..addAll({for (final item in progress.steps.values) ...item.required});
    final personal = progress.steps['personal-information']!.data;
    final skillsData = progress.steps['skills-and-experiences']!.data;
    final work = progress.steps['work-preferences']!.data;
    void texts(Map<String, dynamic> data, Map<String, String> mapping) {
      for (final entry in mapping.entries) {
        text(entry.value).text = data[entry.key]?.toString() ?? '';
      }
    }

    String? id(dynamic object) =>
        object is Map ? object['id']?.toString() : null;
    final field = personal['professional_field'];
    _field = field is Map && field['id'] is int
        ? ProfessionalField(
            field['name']?.toString() ?? '',
            '',
            const [],
            id: field['id'] as int,
          )
        : null;
    fields = [if (_field != null) _field!];
    texts(personal, {
      'full_name': 'name',
      'email': 'email',
      'phone_country_code': 'phoneCountryCode',
      'phone_number': 'phone',
      'whatsapp_country_code': 'whatsappCountryCode',
      'whatsapp_number': 'whatsapp',
      'date_of_birth': 'birthday',
    });
    if (personal['full_name'] == null) text('name').text = seedName;
    if (personal['email'] == null) text('email').text = seedEmail;
    birthday = DateTime.tryParse(personal['date_of_birth']?.toString() ?? '');
    selections.addAll({
      'gender': personal['gender'] as String?,
      'religion': personal['religion'] as String?,
      'nationality': id(personal['nationality_country']),
      'country': id(personal['residence_country']),
      'city': id(personal['residence_city']),
      'job': id(skillsData['job_title']),
      'level': skillsData['seniority_level'] as String?,
      'currentCurrency': id(work['current_currency']),
      'expectedCurrency': id(work['expected_currency']),
      'relocate': work['willing_to_relocate'] is bool
          ? work['willing_to_relocate'] == true
                ? 'Yes'
                : 'No'
          : null,
    });
    cv = null;
    savedCv = personal['cv'] is Map
        ? Map<String, dynamic>.from(personal['cv'] as Map)
        : null;
    languages.clear();
    for (final language in personal['languages'] as List? ?? []) {
      languages.add(
        LanguageEntry(
          _nextId++,
          language: id(language),
          level: language['proficiency_level'] as String?,
        ),
      );
    }
    if (languages.isEmpty) languages.add(LanguageEntry(_nextId++));
    texts(skillsData, {
      'professional_summary': 'summary',
      'years_of_experience': 'years',
      'linkedin_url': 'LinkedIn',
      'github_url': 'GitHub',
      'behance_url': 'Behance',
      'portfolio_url': 'Portfolio',
    });
    for (final entry in {
      'skills': 'skill_ids',
      'tools': 'tool_ids',
      'industries': 'industry_ids',
    }.entries) {
      multiSelections[entry.value] = {
        for (final item in skillsData[entry.key] as List? ?? [])
          if (id(item) != null) id(item)!,
      };
    }
    experiences.clear();
    for (final item in skillsData['experiences'] as List? ?? []) {
      final entry = ExperienceEntry(_nextId++)
        ..serverId = item['id'] as int?
        ..current = item['currently_working'] == true
        ..from = DateTime.tryParse(item['started_at']?.toString() ?? '')
        ..to = DateTime.tryParse(item['ended_at']?.toString() ?? '');
      experiences.add(entry);
      final prefix = 'experience_${entry.id}_';
      texts(Map<String, dynamic>.from(item as Map), {
        'job_title': '${prefix}job',
        'company_name': '${prefix}company',
        'company_url': '${prefix}url',
        'started_at': '${prefix}from',
        'ended_at': '${prefix}to',
        'responsibilities': '${prefix}description',
      });
    }
    projects.clear();
    for (final item in skillsData['projects'] as List? ?? []) {
      final entry = ProjectEntry(_nextId++)..serverId = item['id'] as int?;
      for (final media in item['images'] as List? ?? []) {
        if (media is Map) {
          entry.savedImages.add(Map<String, dynamic>.from(media));
        }
      }
      projects.add(entry);
      final prefix = 'project_${entry.id}_';
      texts(Map<String, dynamic>.from(item as Map), {
        'name': '${prefix}name',
        'description': '${prefix}description',
        'url': '${prefix}url',
      });
    }
    for (final key in ['work_types', 'work_modes']) {
      multiSelections[key] = Set<String>.from(work[key] as List? ?? []);
    }
    texts(work, {
      'notice_period_days': 'noticeDays',
      'current_salary': 'currentSalary',
      'expected_salary_min': 'minSalary',
      'expected_salary_max': 'maxSalary',
    });
    personalFailure = null;
    stepFailure = null;
    step = progress.step;
    refresh();
  }
}
