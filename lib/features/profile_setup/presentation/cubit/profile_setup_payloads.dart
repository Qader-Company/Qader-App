import '../../domain/entities/profile_cv.dart';
import 'profile_setup_cubit.dart';

/// Builds the onboarding API bodies from the profile setup form, validating
/// as it goes. Throws [FormatException] with a translation key when the form
/// is incomplete or invalid. Values are API IDs and enum codes, never labels.
extension ProfileSetupPayloads on ProfileSetupCubit {
  /// Body of `POST onboarding/personal-information` (without the CV file).
  Map<String, dynamic> personalInformationPayload() {
    if (selectedField?.id == null || formFields == null) {
      throw const FormatException('profile_step_save_failed');
    }
    final values = <String, dynamic>{
      'professional_field_id': selectedField!.id,
    };
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
    return values;
  }

  /// Body of `POST onboarding/skills-and-experiences` (with project images)
  /// or, when [work], `POST onboarding/work-preferences`.
  ({Map<String, dynamic> values, Map<int, List<ProfileCv>> images})
  detailsPayload({required bool work}) {
    if (formFields == null) {
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
      check(value != null && options(lookup).any((item) => item.key == value));
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
          check(
            !requiresField(entry.key) || selectedValues(entry.key).isNotEmpty,
          );
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
        check(!requiresField('experiences') || experiences.isNotEmpty);
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
                if (entry.serverId != null) 'id': entry.serverId,
                'job_title': content('${prefix}job', required: true),
                'company_name': content('${prefix}company', required: true),
                'company_url': url('${prefix}url'),
                'started_at': date(entry.from!),
                if (!entry.current && entry.to != null)
                  'ended_at': date(entry.to!),
                'currently_working': entry.current,
                'responsibilities': content('${prefix}description', max: 5000),
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
                if (entry.serverId != null) 'id': entry.serverId,
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
    return (values: values, images: images);
  }
}
