part of 'profile_setup_cubit.dart';

extension ProfileProgressRestore on ProfileSetupCubit {
  bool get hasProgressRepository => _progressRepository != null;

  /// Also used after each save, so a previously completed later step is skipped.
  /// Failure retains the draft and retry only repeats GET, never the successful POST.
  Future<bool> restoreProgress() async {
    if (_progressRepository == null || busy || isClosed) return false;
    _set(
      state.copyWith(
        progressLoading: true,
        progressPending: true,
        progressFailure: null,
      ),
    );
    try {
      final result = await _progressRepository!.load();
      if (isClosed) return false;
      if (result.isError) {
        progressFailure = result.getErrorOrThrow();
        return false;
      }
      applyProgress(result.getOrThrow());
      progressPending = false;
      return true;
    } on Object {
      if (!isClosed) {
        progressFailure = const ServerFailure(
          message: 'profile_progress_failed',
        );
      }
      return false;
    } finally {
      if (!isClosed) {
        progressLoading = false;
      }
    }
  }

  void applyProgress(OnboardingProgress progress) {
    if (isClosed) return;
    // Invalidate earlier lookup responses before restoring another server snapshot.
    for (final lookup in ProfileLookup.values) {
      _lookupRequests[lookup] = (_lookupRequests[lookup] ?? 0) + 1;
    }
    _setLookups(options: {}, loading: {}, failures: {});
    _setSelections({});
    _setMultiSelections({});
    final seedName = text('name').text;
    final seedEmail = text('email').text;
    for (final controller in _text.values) {
      controller.clear();
    }
    formFields = {for (final item in progress.steps.values) ...item.visible};
    _setRequired(
      {for (final item in progress.steps.values) ...item.required},
      {
        for (final item in progress.steps.values)
          for (final rule in item.conditional) rule.field: rule,
      },
    );
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
    text('birthday').text = _dateText(birthday);
    selectAll({
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
    final restoredLanguages = [
      for (final language in personal['languages'] as List? ?? [])
        LanguageEntry(
          _nextId++,
          language: id(language),
          level: language['proficiency_level'] as String?,
        ),
    ];
    _setEntries(
      languages: restoredLanguages.isEmpty
          ? [LanguageEntry(_nextId++)]
          : restoredLanguages,
    );
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
      selectValues(entry.value, {
        for (final item in skillsData[entry.key] as List? ?? [])
          if (id(item) != null) id(item)!,
      });
    }
    final restoredExperiences = <ExperienceEntry>[];
    for (final item in skillsData['experiences'] as List? ?? []) {
      final current = item['currently_working'] == true;
      final entry = ExperienceEntry(
        _nextId++,
        serverId: item['id'] as int?,
        current: current,
        from: DateTime.tryParse(item['started_at']?.toString() ?? ''),
        // A current job has no end date, even if the server kept an old one.
        to: current
            ? null
            : DateTime.tryParse(item['ended_at']?.toString() ?? ''),
      );
      restoredExperiences.add(entry);
      final prefix = 'experience_${entry.id}_';
      texts(Map<String, dynamic>.from(item as Map), {
        'job_title': '${prefix}job',
        'company_name': '${prefix}company',
        'company_url': '${prefix}url',
        'responsibilities': '${prefix}description',
      });
      text('${prefix}from').text = _dateText(entry.from);
      text('${prefix}to').text = _dateText(entry.to);
    }
    _setEntries(experiences: restoredExperiences);
    final restoredProjects = <ProjectEntry>[];
    for (final item in skillsData['projects'] as List? ?? []) {
      final entry = ProjectEntry(
        _nextId++,
        serverId: item['id'] as int?,
        savedImages: List.unmodifiable([
          for (final media in item['images'] as List? ?? [])
            if (media is Map) Map<String, dynamic>.from(media),
        ]),
      );
      restoredProjects.add(entry);
      final prefix = 'project_${entry.id}_';
      texts(Map<String, dynamic>.from(item as Map), {
        'name': '${prefix}name',
        'description': '${prefix}description',
        'url': '${prefix}url',
      });
    }
    _setEntries(projects: restoredProjects);
    for (final key in ['work_types', 'work_modes']) {
      selectValues(key, Set<String>.from(work[key] as List? ?? []));
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
    _textsChanged();
  }
}

/// Same format the date picker writes (see `ProfileDate`).
String _dateText(DateTime? date) => date == null
    ? ''
    : '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
