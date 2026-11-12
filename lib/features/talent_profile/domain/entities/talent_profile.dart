/// Not sent by `GET /talent/profile`; only the preview routes set it.
enum TalentProfileStatus { accepted, rejected, restricted }

enum ProfileLinkKind { linkedin, behance, portfolio, github }

class ProfileLink {
  const ProfileLink(this.kind, this.url);
  final ProfileLinkKind kind;
  final String url;
}

class ProfileLanguage {
  const ProfileLanguage(this.name, this.level);
  final String name;

  /// Backend `proficiency_level` code, e.g. `a1`, `native`.
  final String level;
}

class ProfileExperience {
  const ProfileExperience({
    required this.title,
    this.company = '',
    this.companyUrl,
    this.start,
    this.end,
    this.current = false,
    this.description = '',
  });
  final String title, company, description;
  final String? companyUrl;
  final DateTime? start, end;
  final bool current;
}

class ProfileProject {
  const ProfileProject({required this.name, this.description = '', this.url});
  final String name, description;
  final String? url;
}

/// The talent's profile (`GET /talent/profile`), flattened from the
/// backend's `personal-information`, `skills-and-experiences` and
/// `work-preferences` sections.
class TalentProfile {
  const TalentProfile({
    required this.name,
    this.title = '',
    this.email = '',
    this.phone = '',
    this.whatsapp = '',
    this.summary = '',
    this.avatarUrl,
    this.status,
    this.reviewAvailableAt,
    this.completion,
    this.available,
    this.location = '',
    this.yearsOfExperience,
    this.links = const [],
    this.nationality = '',
    this.religion = '',
    this.gender = '',
    this.city = '',
    this.country = '',
    this.dateOfBirth,
    this.languages = const [],
    this.skills = const [],
    this.tools = const [],
    this.experiences = const [],
    this.projects = const [],
    this.workTypes = const [],
    this.workModes = const [],
    this.expectedSalary = '',
    this.currentSalary = '',
    this.noticePeriodDays,
    this.willingToRelocate,
    this.cvFileName,
    this.visibleFields,
  });

  final String name, title, email, phone, whatsapp, summary;
  final String? avatarUrl;

  /// `null` when the backend sends no profile status (the live profile).
  final TalentProfileStatus? status;
  final DateTime? reviewAvailableAt;

  /// Profile completion from 0 to 1; `null` hides the progress bar.
  final double? completion;

  /// Availability switch value; `null` hides the switch.
  final bool? available;

  /// City and country of residence, e.g. "Cairo, Egypt".
  final String location;
  final int? yearsOfExperience;
  final List<ProfileLink> links;

  final String nationality, city, country;

  /// Backend codes, e.g. `islam`, `male`.
  final String religion, gender;
  final DateTime? dateOfBirth;
  final List<ProfileLanguage> languages;

  final List<String> skills, tools;
  final List<ProfileExperience> experiences;
  final List<ProfileProject> projects;

  /// Backend codes, e.g. `full_time`, `remote`.
  final List<String> workTypes, workModes;

  /// Ready to display, e.g. "20,000–30,000 EGP".
  final String expectedSalary, currentSalary;
  final int? noticePeriodDays;
  final bool? willingToRelocate;
  final String? cvFileName;

  /// The backend's `visible_fields` of every section; `null` shows all.
  final Set<String>? visibleFields;

  /// Whether the backend wants [field] shown (`visible_fields`).
  bool shows(String field) => visibleFields?.contains(field) ?? true;

  TalentProfile copyWith({
    String? name,
    String? title,
    String? email,
    String? phone,
    String? whatsapp,
    String? summary,
    TalentProfileStatus? status,
    DateTime? reviewAvailableAt,
  }) => TalentProfile(
    name: name ?? this.name,
    title: title ?? this.title,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    whatsapp: whatsapp ?? this.whatsapp,
    summary: summary ?? this.summary,
    avatarUrl: avatarUrl,
    status: status ?? this.status,
    reviewAvailableAt: reviewAvailableAt ?? this.reviewAvailableAt,
    completion: completion,
    available: available,
    location: location,
    yearsOfExperience: yearsOfExperience,
    links: links,
    nationality: nationality,
    religion: religion,
    gender: gender,
    city: city,
    country: country,
    dateOfBirth: dateOfBirth,
    languages: languages,
    skills: skills,
    tools: tools,
    experiences: experiences,
    projects: projects,
    workTypes: workTypes,
    workModes: workModes,
    expectedSalary: expectedSalary,
    currentSalary: currentSalary,
    noticePeriodDays: noticePeriodDays,
    willingToRelocate: willingToRelocate,
    cvFileName: cvFileName,
    visibleFields: visibleFields,
  );

  /// Parses the `data` object of `GET /talent/profile`. Missing sections
  /// and fields fall back to empty values.
  factory TalentProfile.fromJson(Map<String, dynamic> json) {
    final sections = <String, Map<String, dynamic>>{};
    final visible = <String>{};
    for (final item in _list(json['sections'])) {
      final section = _map(item);
      final key = _string(section?['key']);
      if (section == null || key == null) continue;
      sections[key] = _map(section['data']) ?? const {};
      visible.addAll(_list(section['visible_fields']).whereType<String>());
    }
    final personal = sections['personal-information'] ?? const {};
    final skills = sections['skills-and-experiences'] ?? const {};
    final work = sections['work-preferences'] ?? const {};
    final city = _name(personal['residence_city']);
    final country = _name(personal['residence_country']);
    final experiences = [
      for (final item in _list(skills['experiences']))
        if (_map(item) case final raw?)
          if (_string(raw['job_title']) case final title?)
            (
              _int(raw['display_order']) ?? 0,
              ProfileExperience(
                title: title,
                company: _string(raw['company_name']) ?? '',
                companyUrl: _string(raw['company_url']),
                start: _date(raw['started_at']),
                end: _date(raw['ended_at']),
                current: raw['currently_working'] == true,
                description: _string(raw['responsibilities']) ?? '',
              ),
            ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final projects = [
      for (final item in _list(skills['projects']))
        if (_map(item) case final raw?)
          if (_string(raw['name']) case final name?)
            (
              _int(raw['display_order']) ?? 0,
              ProfileProject(
                name: name,
                description: _string(raw['description']) ?? '',
                url: _string(raw['url']),
              ),
            ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return TalentProfile(
      name: _string(personal['full_name']) ?? '',
      title: _name(skills['job_title']),
      email: _string(personal['email']) ?? '',
      phone: _phone(personal['phone_country_code'], personal['phone_number']),
      whatsapp: _phone(
        personal['whatsapp_country_code'],
        personal['whatsapp_number'],
      ),
      summary: _string(skills['professional_summary']) ?? '',
      location: [city, country].where((part) => part.isNotEmpty).join(', '),
      yearsOfExperience: _int(skills['years_of_experience']),
      links: [
        for (final (kind, key) in const [
          (ProfileLinkKind.linkedin, 'linkedin_url'),
          (ProfileLinkKind.portfolio, 'portfolio_url'),
          (ProfileLinkKind.github, 'github_url'),
        ])
          if (_string(skills[key]) case final url?) ProfileLink(kind, url),
      ],
      nationality: _name(personal['nationality_country']),
      religion: _string(personal['religion']) ?? '',
      gender: _string(personal['gender']) ?? '',
      city: city,
      country: country,
      dateOfBirth: _date(personal['date_of_birth']),
      languages: [
        for (final item in _list(personal['languages']))
          if (_map(item) case final raw?)
            if (_string(raw['name']) case final name?)
              ProfileLanguage(name, _string(raw['proficiency_level']) ?? ''),
      ],
      skills: _names(skills['skills']),
      tools: _names(skills['tools']),
      experiences: [for (final entry in experiences) entry.$2],
      projects: [for (final entry in projects) entry.$2],
      workTypes: _list(work['work_types']).whereType<String>().toList(),
      workModes: _list(work['work_modes']).whereType<String>().toList(),
      expectedSalary: _salaryRange(
        work['expected_salary_min'],
        work['expected_salary_max'],
        _string(_map(work['expected_currency'])?['code']),
      ),
      currentSalary: _salaryRange(
        work['current_salary'],
        null,
        _string(_map(work['current_currency'])?['code']),
      ),
      noticePeriodDays: _int(work['notice_period_days']),
      willingToRelocate: work['willing_to_relocate'] is bool
          ? work['willing_to_relocate'] as bool
          : null,
      cvFileName:
          _string(_map(personal['cv'])?['file_name']) ??
          _string(_map(personal['cv'])?['name']),
      visibleFields: visible.isEmpty ? null : visible,
    );
  }
}

Map<String, dynamic>? _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : null;
List<Object?> _list(Object? raw) => raw is List ? raw : const [];
String? _string(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;
int? _int(Object? raw) =>
    raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
DateTime? _date(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;

/// `name` of a `{id, name}` lookup object.
String _name(Object? raw) => _string(_map(raw)?['name']) ?? '';

List<String> _names(Object? raw) => [
  for (final item in _list(raw))
    if (_name(item) case final name when name.isNotEmpty) name,
];

String _phone(Object? code, Object? number) =>
    [_string(code), _string(number)].nonNulls.join(' ');

/// "20,000–30,000 EGP" from the backend's decimal strings ("20000.00").
String _salaryRange(Object? min, Object? max, String? currency) {
  final amounts = [_amount(min), _amount(max)].nonNulls.join('–');
  if (amounts.isEmpty) return '';
  return currency == null ? amounts : '$amounts $currency';
}

String? _amount(Object? raw) {
  final value = raw is num ? raw : num.tryParse('${raw ?? ''}');
  if (value == null) return null;
  final digits = value.round().abs().toString();
  final grouped = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  return grouped.toString();
}
