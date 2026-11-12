import 'package:flutter_test/flutter_test.dart';
import 'package:qader/features/profile_setup/domain/repositories/professional_fields_repository.dart';
import 'package:qader/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:qader/features/profile_setup/presentation/cubit/profile_setup_payloads.dart';

class _Fields extends Fake implements ProfessionalFieldsRepository {}

const _design = ProfessionalField('Design', '', [], id: 3);

ProfileSetupCubit _form(Set<String> visible) {
  final form = ProfileSetupCubit(fieldsRepository: _Fields())
    ..fields = [_design];
  form.chooseField(_design);
  form.formFields = visible;
  List<ProfileLookupOption> ids(Map<int, String> items) => [
    for (final entry in items.entries)
      ProfileLookupOption(value: entry.key, label: entry.value),
  ];
  List<ProfileLookupOption> codes(List<String> items) => [
    for (final code in items) ProfileLookupOption(value: code, label: code),
  ];
  form.lookupOptions.addAll({
    ProfileLookup.countries: ids({1: 'Egypt', 2: 'Saudi Arabia'}),
    ProfileLookup.cities: ids({10: 'Cairo'}),
    ProfileLookup.languages: ids({1: 'Arabic', 2: 'English'}),
    ProfileLookup.languageProficiencies: codes(['b1', 'native']),
    ProfileLookup.genders: codes(['male', 'female']),
    ProfileLookup.jobTitles: ids({13: 'UI/UX Designer'}),
    ProfileLookup.seniorityLevels: codes(['junior', 'senior']),
    ProfileLookup.skills: ids({16: 'User Research', 18: 'Visual Design'}),
    ProfileLookup.workTypes: codes(['full_time']),
    ProfileLookup.workModes: codes(['remote']),
    ProfileLookup.currencies: ids({1: 'EGP'}),
  });
  return form;
}

Matcher _fails(String key) =>
    throwsA(isA<FormatException>().having((e) => e.message, 'key', key));

void main() {
  group('personal information', () {
    ProfileSetupCubit filled() {
      final form = _form({
        'full_name',
        'phone_number',
        'gender',
        'residence_country_id',
        'residence_city_id',
        'date_of_birth',
        'languages',
      });
      form.text('name').text = '  Ahmed Wael ';
      form.text('phoneCountryCode').text = '+20';
      form.text('phone').text = '106 527-5078';
      form.selections.addAll({'gender': 'male', 'country': '1', 'city': '10'});
      form.birthday = DateTime(1998, 3, 7);
      form.languages
        ..clear()
        ..addAll([
          LanguageEntry(1, language: '1', level: 'native'),
          LanguageEntry(2, language: '2', level: 'b1'),
          LanguageEntry(3),
        ]);
      return form;
    }

    test('maps the form to API ids and codes', () async {
      final form = filled();
      addTearDown(form.close);
      expect(form.personalInformationPayload(), {
        'professional_field_id': 3,
        'full_name': 'Ahmed Wael',
        'phone_country_code': '+20',
        'phone_number': '1065275078',
        'gender': 'male',
        'residence_country_id': 1,
        'residence_city_id': 10,
        'date_of_birth': '1998-03-07',
        'languages': [
          {'language_id': 1, 'proficiency_level': 'native'},
          {'language_id': 2, 'proficiency_level': 'b1'},
        ],
      });
    });

    test('rejects invalid phone, missing name and duplicate languages', () {
      final form = filled();
      addTearDown(form.close);
      form.text('phone').text = '123';
      expect(form.personalInformationPayload, _fails('profile_phone_invalid'));
      form.text('phone').text = '1065275078';
      form.text('name').text = ' ';
      expect(
        form.personalInformationPayload,
        _fails('profile_personal_required'),
      );
      form.text('name').text = 'Ahmed';
      form.languages.add(LanguageEntry(4, language: '1', level: 'b1'));
      expect(
        form.personalInformationPayload,
        _fails('profile_languages_duplicate'),
      );
      form.languages.removeLast();
      form.languages.add(LanguageEntry(5, language: '2'));
      expect(
        form.personalInformationPayload,
        _fails('profile_language_incomplete'),
      );
    });

    test('only sends fields the backend asks for', () {
      final form = filled()..formFields = {'full_name'};
      addTearDown(form.close);
      expect(form.personalInformationPayload(), {
        'professional_field_id': 3,
        'full_name': 'Ahmed Wael',
      });
    });
  });

  group('skills and experience', () {
    ProfileSetupCubit filled() {
      final form = _form({
        'professional_summary',
        'job_title_id',
        'seniority_level',
        'years_of_experience',
        'skill_ids',
        'linkedin_url',
        'experiences',
        'projects',
      });
      form.text('summary').text = 'Designer.';
      form.text('years').text = '4';
      form.text('LinkedIn').text = 'https://linkedin.com/in/ahmed';
      form.selections.addAll({'job': '13', 'level': 'senior'});
      form.selectValues('skill_ids', {'16', '18'});
      form.addExperience();
      final job = form.experiences.single
        ..from = DateTime(2022)
        ..current = true;
      form.text('experience_${job.id}_job').text = 'Designer';
      form.text('experience_${job.id}_company').text = 'Qader';
      form.addProject();
      final project = form.projects.single;
      form.text('project_${project.id}_name').text = 'Portfolio';
      return form;
    }

    test('builds the body with ids, dates and ordered entries', () {
      final form = filled();
      addTearDown(form.close);
      final (:values, :images) = form.detailsPayload(work: false);
      expect(values['job_title_id'], 13);
      expect(values['seniority_level'], 'senior');
      expect(values['years_of_experience'], 4);
      expect(values['skill_ids'], unorderedEquals([16, 18]));
      expect(values['linkedin_url'], 'https://linkedin.com/in/ahmed');
      expect(values['experiences'], [
        {
          'job_title': 'Designer',
          'company_name': 'Qader',
          'company_url': '',
          'started_at': '2022-01-01',
          'currently_working': true,
          'responsibilities': '',
          'display_order': 0,
        },
      ]);
      expect((values['projects'] as List).single['name'], 'Portfolio');
      expect(images, {0: isEmpty});
    });

    test('rejects missing start dates, bad links and years', () {
      final form = filled();
      addTearDown(form.close);
      form.experiences.single.from = null;
      expect(
        () => form.detailsPayload(work: false),
        _fails('profile_details_invalid'),
      );
      form.experiences.single.from = DateTime(2022);
      form.text('LinkedIn').text = 'linkedin.com/in/ahmed';
      expect(
        () => form.detailsPayload(work: false),
        _fails('profile_details_invalid'),
      );
      form.text('LinkedIn').text = 'https://linkedin.com/in/ahmed';
      form.text('years').text = '120';
      expect(
        () => form.detailsPayload(work: false),
        _fails('profile_details_invalid'),
      );
    });
  });

  test('work preferences need a valid salary range', () {
    final form = _form({
      'work_types',
      'work_modes',
      'notice_period_days',
      'expected_salary',
    });
    addTearDown(form.close);
    form.selectValues('work_types', {'full_time'});
    form.selectValues('work_modes', {'remote'});
    form.text('noticeDays').text = '30';
    form.text('minSalary').text = '20000';
    form.text('maxSalary').text = '30000';
    form.selections['expectedCurrency'] = '1';
    expect(form.detailsPayload(work: true).values, {
      'work_types': ['full_time'],
      'work_modes': ['remote'],
      'notice_period_days': 30,
      'expected_salary_min': 20000,
      'expected_salary_max': 30000,
      'expected_currency_id': 1,
    });
    form.text('maxSalary').text = '10000';
    expect(
      () => form.detailsPayload(work: true),
      _fails('profile_details_invalid'),
    );
  });
}
