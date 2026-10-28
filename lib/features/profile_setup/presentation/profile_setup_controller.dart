import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/network/failure.dart';
import '../../../core/network/either.dart';
import '../domain/entities/professional_field.dart';
import '../domain/repositories/professional_fields_repository.dart';
import '../domain/repositories/profile_lookups_repository.dart';
import '../domain/entities/profile_lookup.dart';
import '../domain/entities/profile_cv.dart';
import '../domain/repositories/onboarding_steps_repository.dart';
export '../domain/entities/profile_lookup.dart';
export '../domain/entities/professional_field.dart';

class ProfileSetupSeed {
  const ProfileSetupSeed({required this.name, required this.email});
  final String name;
  final String email;
}

class LanguageEntry {
  LanguageEntry(this.id, {this.language, this.level});
  final int id;
  String? language;
  String? level;
}

class ExperienceEntry {
  ExperienceEntry(this.id);
  final int id;
  bool current = false;
  DateTime? from;
  DateTime? to;
}

class ProjectEntry {
  ProjectEntry(this.id);
  final int id;
  final images = <PlatformFile>[];
}

/// Field selection and personal information persist through the onboarding APIs.
class ProfileSetupController extends ChangeNotifier {
  ProfileSetupController({
    ProfileSetupSeed? seed,
    ProfessionalFieldsRepository? fieldsRepository,
    ProfileLookupsRepository? lookupsRepository,
    OnboardingStepsRepository? stepsRepository,
  }) : _fieldsRepository = fieldsRepository,
       _lookupsRepository = lookupsRepository,
       _stepsRepository = stepsRepository {
    text('name').text =
        seed?.name ?? (fieldsRepository == null ? 'Olivia Rhye' : '');
    text('email').text =
        seed?.email ??
        (fieldsRepository == null ? 'olivia@untitledui.com' : '');
    if (fieldsRepository != null) {
      skills.clear();
      experiences.clear();
      projects.clear();
      languages
        ..clear()
        ..add(LanguageEntry(1));
    }
    fields = fieldsRepository == null ? ProfessionalField.values : [];
    _field = fieldsRepository == null ? fields.first : null;
  }
  final ProfessionalFieldsRepository? _fieldsRepository;
  final ProfileLookupsRepository? _lookupsRepository;
  final OnboardingStepsRepository? _stepsRepository;
  bool savingPersonalInfo = false;
  bool savingDetails = false;
  bool get busy => savingField || savingPersonalInfo || savingDetails;
  Failure? stepFailure;
  final multiSelections = <String, Set<String>>{};
  Set<String> selectedValues(String key) => multiSelections[key] ?? const {};
  void selectValues(String key, Set<String> values) {
    multiSelections[key] = Set.of(values);
    notifyListeners();
  }

  Failure? personalFailure;

  Future<bool> savePersonalInformation() async {
    if (busy || !isConnected || _disposed) return false;
    savingPersonalInfo = true;
    personalFailure = null;
    notifyListeners();
    try {
      final repository = _stepsRepository;
      if (repository == null || _field?.id == null || formFields == null) {
        throw const FormatException('profile_step_save_failed');
      }
      final values = <String, dynamic>{'professional_field_id': _field!.id};
      if (showsField('full_name')) {
        final name = text('name').text.trim();
        if (name.isEmpty) {
          throw const FormatException('profile_personal_required');
        }
        values['full_name'] = name;
      }
      for (final name in ['phone', 'whatsapp']) {
        if (!showsField('${name}_number')) continue;
        final code = text('${name}CountryCode').text.trim();
        final number = text(name).text.replaceAll(RegExp(r'[\s()-]'), '');
        if (!RegExp(r'^\+[1-9][0-9]{0,3}$').hasMatch(code) ||
            !RegExp(r'^[0-9]{7,15}$').hasMatch(number)) {
          throw const FormatException('profile_phone_invalid');
        }
        values['${name}_country_code'] = code;
        values['${name}_number'] = number;
      }
      for (final entry in {
        'gender': ProfileLookup.genders,
        'religion': ProfileLookup.religions,
      }.entries) {
        if (!showsField(entry.key)) continue;
        final selected = value(entry.key);
        if (selected == null && entry.key != 'gender') continue;
        if (!options(entry.value).any((option) => option.key == selected)) {
          throw const FormatException('profile_personal_required');
        }
        values[entry.key] = selected;
      }
      for (final entry in {
        'nationality': 'nationality_country_id',
        'country': 'residence_country_id',
        'city': 'residence_city_id',
      }.entries) {
        if (!showsField(entry.value) || value(entry.key) == null) continue;
        final id = lookupId(
          entry.key == 'city' ? ProfileLookup.cities : ProfileLookup.countries,
          value(entry.key),
        );
        if (id == null) {
          throw const FormatException('profile_personal_required');
        }
        values[entry.value] = id;
      }
      if (showsField('date_of_birth') && birthday != null) {
        final date = birthday!;
        values['date_of_birth'] =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      if (showsField('languages')) {
        final entries = <Map<String, dynamic>>[];
        final ids = <int>{};
        for (final entry in languages) {
          if (entry.language == null && entry.level == null) continue;
          final id = lookupId(ProfileLookup.languages, entry.language);
          if (id == null ||
              !options(
                ProfileLookup.languageProficiencies,
              ).any((option) => option.key == entry.level)) {
            throw const FormatException('profile_language_incomplete');
          }
          if (!ids.add(id)) {
            throw const FormatException('profile_languages_duplicate');
          }
          entries.add({'language_id': id, 'proficiency_level': entry.level});
        }
        values['languages'] = entries;
      }
      final file = cv;
      final result = await repository.savePersonalInformation(
        values,
        visibleFields: formFields!,
        cv: file == null
            ? null
            : ProfileCv(name: file.name, path: file.path, bytes: file.bytes),
      );
      if (_disposed) return false;
      personalFailure = result.isError ? result.getErrorOrThrow() : null;
      return result.isSuccess;
    } on FormatException catch (error) {
      if (!_disposed) personalFailure = ServerFailure(message: error.message);
      return false;
    } on Object {
      if (!_disposed) {
        personalFailure = const ServerFailure(
          message: 'profile_step_save_failed',
        );
      }
      return false;
    } finally {
      if (!_disposed) {
        savingPersonalInfo = false;
        notifyListeners();
      }
    }
  }

  Future<bool> saveDetails({required bool work}) async {
    if (busy || !isConnected || _disposed) return false;
    savingDetails = true;
    stepFailure = null;
    notifyListeners();
    try {
      final repository = _stepsRepository;
      if (repository == null || formFields == null) {
        throw const FormatException('profile_step_save_failed');
      }
      void check(bool valid) {
        if (!valid) throw const FormatException('profile_details_invalid');
      }

      String content(String key, {int max = 255, bool required = false}) {
        final value = text(key).text.trim();
        check(value.length <= max && (!required || value.isNotEmpty));
        return value;
      }

      int id(ProfileLookup lookup, String? key) {
        final value = lookupId(lookup, key);
        check(value != null);
        return value!;
      }

      String code(ProfileLookup lookup, String? value) {
        check(
          value != null && options(lookup).any((item) => item.key == value),
        );
        return value!;
      }

      String url(String key, {bool required = false}) {
        final value = content(key, required: required);
        final uri = Uri.tryParse(value);
        check(
          value.isEmpty ||
              uri != null &&
                  {'http', 'https'}.contains(uri.scheme) &&
                  uri.host.isNotEmpty,
        );
        return value;
      }

      num amount(String key) {
        final value = num.tryParse(content(key));
        check(value != null && value.isFinite && value >= 0);
        return value!;
      }

      String date(DateTime value) =>
          '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      final values = <String, dynamic>{};
      final images = <int, List<ProfileCv>>{};
      if (!work) {
        if (showsField('professional_summary')) {
          values['professional_summary'] = content('summary', max: 5000);
        }
        if (showsField('job_title_id')) {
          values['job_title_id'] = id(ProfileLookup.jobTitles, value('job'));
        }
        if (showsField('seniority_level')) {
          values['seniority_level'] = code(
            ProfileLookup.seniorityLevels,
            value('level'),
          );
        }
        if (showsField('years_of_experience')) {
          final years = int.tryParse(content('years'));
          check(years != null && years >= 0 && years <= 80);
          values['years_of_experience'] = years;
        }
        for (final entry in {
          'skill_ids': ProfileLookup.skills,
          'tool_ids': ProfileLookup.tools,
          'industry_ids': ProfileLookup.industries,
        }.entries) {
          if (showsField(entry.key)) {
            values[entry.key] = selectedValues(
              entry.key,
            ).map((key) => id(entry.value, key)).toList();
          }
        }
        for (final entry in {
          'linkedin_url': 'LinkedIn',
          'github_url': 'GitHub',
          'behance_url': 'Behance',
          'portfolio_url': 'Portfolio',
        }.entries) {
          if (!showsField(entry.key)) continue;
          final link = url(entry.value, required: entry.key == 'linkedin_url');
          if (link.isNotEmpty) values[entry.key] = link;
        }
        if (showsField('experiences')) {
          values['experiences'] = [
            for (var i = 0; i < experiences.length; i++)
              (() {
                final entry = experiences[i];
                final prefix = 'experience_${entry.id}_';
                check(
                  entry.from != null &&
                      (entry.current ||
                          entry.to == null ||
                          !entry.to!.isBefore(entry.from!)),
                );
                return {
                  'job_title': content('${prefix}job', required: true),
                  'company_name': content('${prefix}company', required: true),
                  'company_url': url('${prefix}url'),
                  'started_at': date(entry.from!),
                  if (!entry.current && entry.to != null)
                    'ended_at': date(entry.to!),
                  'currently_working': entry.current,
                  'responsibilities': content(
                    '${prefix}description',
                    max: 5000,
                  ),
                  'display_order': i,
                };
              })(),
          ];
        }
        if (showsField('projects')) {
          values['projects'] = [
            for (var i = 0; i < projects.length; i++)
              (() {
                final entry = projects[i];
                final prefix = 'project_${entry.id}_';
                images[i] = [
                  for (final file in entry.images)
                    ProfileCv(
                      name: file.name,
                      path: file.path,
                      bytes: file.bytes,
                    ),
                ];
                return {
                  'name': content('${prefix}name', required: true),
                  'description': content('${prefix}description', max: 5000),
                  'url': url('${prefix}url'),
                  'display_order': i,
                };
              })(),
          ];
        }
      } else {
        for (final entry in {
          'work_types': ProfileLookup.workTypes,
          'work_modes': ProfileLookup.workModes,
        }.entries) {
          if (!showsField(entry.key)) continue;
          check(selectedValues(entry.key).isNotEmpty);
          values[entry.key] = selectedValues(
            entry.key,
          ).map((key) => code(entry.value, key)).toList();
        }
        if (showsField('notice_period_days')) {
          final days = int.tryParse(content('noticeDays'));
          check(days != null && days >= 0 && days <= 365);
          values['notice_period_days'] = days;
        }
        if (showsField('willing_to_relocate') && value('relocate') != null) {
          check({'Yes', 'No'}.contains(value('relocate')));
          values['willing_to_relocate'] = value('relocate') == 'Yes';
        }
        if (showsField('current_salary')) {
          values['current_salary'] = amount('currentSalary');
          values['current_currency_id'] = id(
            ProfileLookup.currencies,
            value('currentCurrency'),
          );
        }
        if (showsField('expected_salary')) {
          final min = amount('minSalary');
          final max = amount('maxSalary');
          check(max >= min);
          values.addAll({
            'expected_salary_min': min,
            'expected_salary_max': max,
            'expected_currency_id': id(
              ProfileLookup.currencies,
              value('expectedCurrency'),
            ),
          });
        }
      }
      final result = work
          ? await repository.saveWorkPreferences(
              values,
              visibleFields: formFields!,
            )
          : await repository.saveSkillsAndExperiences(
              values,
              visibleFields: formFields!,
              projectImages: images,
            );
      if (_disposed) return false;
      stepFailure = result.isError ? result.getErrorOrThrow() : null;
      return result.isSuccess;
    } on FormatException catch (error) {
      if (!_disposed) stepFailure = ServerFailure(message: error.message);
      return false;
    } on Object {
      if (!_disposed) {
        stepFailure = const ServerFailure(message: 'profile_step_save_failed');
      }
      return false;
    } finally {
      if (!_disposed) {
        savingDetails = false;
        notifyListeners();
      }
    }
  }

  final lookupOptions = <ProfileLookup, List<ProfileLookupOption>>{};
  final lookupLoading = <ProfileLookup>{};
  final lookupFailures = <ProfileLookup, Failure>{};
  final _lookupRequests = <ProfileLookup, int>{};

  List<ProfileLookupOption> options(ProfileLookup lookup) =>
      lookupOptions[lookup] ?? const [];
  int? lookupId(ProfileLookup lookup, String? key) {
    for (final option in options(lookup)) {
      if (option.key == key) return option.id;
    }
    return null;
  }

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
    if (_lookupsRepository == null || _disposed) return;
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
    notifyListeners();
    try {
      final result = await _lookupsRepository.load(
        lookup,
        countryId: countryId,
        professionalFieldId: lookup.isFieldScoped ? _field?.id : null,
      );
      if (_disposed || _lookupRequests[lookup] != request) return;
      result.fold(
        (failure) => lookupFailures[lookup] = failure,
        (items) => lookupOptions[lookup] = items,
      );
    } on Object {
      if (!_disposed && _lookupRequests[lookup] == request) {
        lookupFailures[lookup] = const ServerFailure(
          message: 'profile_lookup_invalid',
        );
      }
    } finally {
      if (!_disposed && _lookupRequests[lookup] == request) {
        lookupLoading.remove(lookup);
        notifyListeners();
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
    notifyListeners();
    if (showsField('residence_city_id')) await loadLookup(ProfileLookup.cities);
  }

  late List<ProfessionalField> fields;
  ProfessionalField? _field;
  ProfessionalField? get selectedField => _field;
  ProfessionalField get field => _field!;
  bool fieldsLoading = false;
  bool savingField = false;
  Failure? fieldFailure;
  Set<String>? formFields;
  bool get isConnected => _fieldsRepository != null;
  bool showsField(String key) =>
      !isConnected || (formFields?.contains(key) ?? false);
  bool _disposed = false;

  Future<void> loadFields() async {
    if (_fieldsRepository == null || fieldsLoading || busy) return;
    fieldsLoading = true;
    fieldFailure = null;
    notifyListeners();
    try {
      final result = await _fieldsRepository.load();
      if (_disposed) return;
      result.fold((failure) => fieldFailure = failure, (value) {
        fields = value;
        final previousId = _field?.id;
        _field = null;
        for (final candidate in fields) {
          if (candidate.id == previousId) _field = candidate;
        }
      });
    } on Object {
      if (!_disposed) {
        fieldFailure = const ServerFailure(
          message: 'profile_fields_load_failed',
        );
      }
    } finally {
      if (!_disposed) {
        fieldsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> saveProfessionalField() async {
    if (fieldsLoading || busy || _field == null) return false;
    if (_fieldsRepository == null) return true;
    final id = _field!.id;
    if (id == null || !fields.contains(_field)) return false;
    savingField = true;
    fieldFailure = null;
    notifyListeners();
    try {
      final result = await _fieldsRepository.select(id);
      if (_disposed) return false;
      fieldFailure = result.isError ? result.getErrorOrThrow() : null;
      if (result.isError) return false;
      final schema = await _fieldsRepository.formFields(id);
      if (_disposed) return false;
      if (schema.isError) {
        fieldFailure = schema.getErrorOrThrow();
        return false;
      }
      formFields = Set.unmodifiable(schema.getOrThrow());
      return true;
    } on Object {
      if (!_disposed) {
        fieldFailure = const ServerFailure(
          message: 'profile_field_save_failed',
        );
      }
      return false;
    } finally {
      if (!_disposed) {
        savingField = false;
        notifyListeners();
      }
    }
  }

  int step = 0;
  int _nextId = 3;
  final _text = <String, TextEditingController>{};
  final selections = <String, String?>{};
  final skills = ['React', 'TypeScript'];
  final languages = [
    LanguageEntry(1, language: 'English', level: 'B1'),
    LanguageEntry(2),
  ];
  final experiences = [ExperienceEntry(1)];
  final projects = [ProjectEntry(1)];
  PlatformFile? cv;
  DateTime? birthday;
  TextEditingController text(String key) =>
      _text.putIfAbsent(key, TextEditingController.new);
  String? value(String key) => selections[key];
  void select(String key, String? value) {
    selections[key] = value;
    notifyListeners();
  }

  void refresh() => notifyListeners();
  void go(int value) {
    stepFailure = null;
    step = value;
    notifyListeners();
  }

  void chooseField(ProfessionalField value) {
    if (busy || fieldsLoading || !fields.contains(value)) return;
    if (_field != value) {
      selections.remove('job');
      formFields = null;
      for (final lookup in ProfileLookup.values.where(
        (item) => item.isFieldScoped,
      )) {
        _lookupRequests[lookup] = (_lookupRequests[lookup] ?? 0) + 1;
        lookupOptions.remove(lookup);
        lookupFailures.remove(lookup);
        lookupLoading.remove(lookup);
      }
      multiSelections.remove('skill_ids');
      multiSelections.remove('tool_ids');
    }
    _field = value;
    fieldFailure = null;
    notifyListeners();
  }

  void addLanguage() {
    languages.add(LanguageEntry(_nextId++));
    notifyListeners();
  }

  void addExperience() {
    experiences.add(ExperienceEntry(_nextId++));
    notifyListeners();
  }

  void addProject() {
    projects.add(ProjectEntry(_nextId++));
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final value in _text.values) {
      value.dispose();
    }
    super.dispose();
  }
}
