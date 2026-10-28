import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/di/service_locator.dart';
import 'package:qader/core/locale/language_manager.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/profile_setup/data/repositories/api_professional_fields_repository.dart';
import 'package:qader/features/profile_setup/presentation/profile_setup_controller.dart';
import 'package:qader/features/profile_setup/presentation/view/profile_setup_view.dart';
import 'package:qader/features/profile_setup/presentation/widgets/basic_info_step.dart';
import 'package:qader/features/profile_setup/presentation/widgets/profile_widgets.dart';
import 'package:qader/features/profile_setup/presentation/widgets/profile_lookup_select.dart';
import 'package:qader/features/profile_setup/presentation/widgets/skills_experience_step.dart';
import 'package:qader/features/profile_setup/data/repositories/api_onboarding_steps_repository.dart';
import 'package:qader/features/profile_setup/data/repositories/api_profile_lookups_repository.dart';

Map<String, Object?> field(int id, String name, {bool active = true}) => {
  'id': id,
  'name': name,
  'description': 'Description of $name',
  'slug': 'field-$id',
  'is_active': active,
};

class _Api extends Fake implements ApiConsumer {
  Object? response = {
    'success': true,
    'data': [
      field(5, 'Customer Service'),
      field(3, 'Design'),
      field(42, 'Product Strategy'),
      field(91, 'Inactive', active: false),
    ],
  };
  Object? patchResponse = {'success': true};
  Object? formResponse = {
    'success': true,
    'data': ['full_name', 'email'],
  };
  Map<String, dynamic>? formQuery;
  Failure? formFailure;
  Map<String, dynamic>? cityQuery;
  Failure? loadFailure;
  Failure? saveFailure;
  Completer<void>? gate;
  int saves = 0;
  String? loadedPath;
  String? savedPath;
  dynamic savedBody;
  int personalSaves = 0;
  Failure? personalSaveFailure;
  Completer<void>? personalGate;
  FormData? personalBody;
  FormData? skillsBody;
  Map<String, dynamic>? workBody;
  Failure? detailsFailure;
  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic) fromJson,
  }) async {
    if (path == ApiOnboardingStepsRepository.skillsPath) {
      skillsBody = data as FormData;
      return detailsFailure == null
          ? Right(fromJson({'success': true}))
          : Left(detailsFailure!);
    }
    if (path == ApiOnboardingStepsRepository.workPath) {
      workBody = data as Map<String, dynamic>;
      return detailsFailure == null
          ? Right(fromJson({'success': true}))
          : Left(detailsFailure!);
    }
    expect(path, '/talent/onboarding/personal-information');
    personalSaves++;
    personalBody = data as FormData;
    await personalGate?.future;
    return personalSaveFailure == null
        ? Right(fromJson({'success': true}))
        : Left(personalSaveFailure!);
  }

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    if (path == ApiProfessionalFieldsRepository.formFieldsPath) {
      formQuery = queryParameters;
      return formFailure == null
          ? Right(fromJson(formResponse))
          : Left(formFailure!);
    }
    if (path.startsWith('/talent/master-data/') &&
        path != ApiProfessionalFieldsRepository.fieldsPath) {
      final key = path.split('/').last;
      final data = switch (key) {
        'genders' => [
          {'value': 'male', 'label': 'Male'},
          {'value': 'female', 'label': 'Female'},
        ],
        'job-titles' => [
          {'id': 52, 'name': 'Backend Engineer', 'is_active': true},
        ],
        'skills' => [
          {'id': 8, 'name': 'Dart'},
          {'id': 3, 'name': 'Flutter'},
        ],
        'tools' => [
          {'id': 10, 'name': 'VS Code'},
          {'id': 11, 'name': 'Android Studio'},
        ],
        'industries' => [
          {'id': 20, 'name': 'Technology'},
        ],
        'seniority-levels' => [
          {'value': 'mid_level', 'label': 'Mid Level'},
        ],
        'work-types' => [
          {'value': 'full_time', 'label': 'Full Time'},
          {'value': 'part_time', 'label': 'Part Time'},
        ],
        'work-modes' => [
          {'value': 'remote', 'label': 'Remote'},
          {'value': 'hybrid', 'label': 'Hybrid'},
        ],
        'religions' => [
          {'value': 'islam', 'label': 'Islam'},
        ],
        'countries' => [
          {'id': 7, 'name': 'Egypt', 'is_active': true},
          {'id': 16, 'name': 'Saudi Arabia', 'is_active': true},
        ],
        'language-proficiencies' => [
          {'value': 'b1', 'label': 'B1 - Intermediate'},
          {'value': 'native', 'label': 'Native'},
        ],
        'languages' => [
          {'id': 9, 'name': 'Arabic', 'is_active': true},
        ],
        'currencies' => [
          {'id': 27, 'name': 'British Pound', 'code': 'GBP', 'is_active': true},
        ],
        _ => [],
      };
      if (key == 'cities') cityQuery = queryParameters;
      return Right(fromJson({'success': true, 'data': data}));
    }
    loadedPath = path;
    await gate?.future;
    return loadFailure == null ? Right(fromJson(response)) : Left(loadFailure!);
  }

  @override
  Future<Either<Failure, T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic) fromJson,
  }) async {
    saves++;
    savedPath = path;
    savedBody = data;
    await gate?.future;
    return saveFailure == null
        ? Right(fromJson(patchResponse))
        : Left(saveFailure!);
  }
}

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File(
              '$path/${locale.languageCode}-${locale.countryCode}.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Api api;
  late ApiProfessionalFieldsRepository repository;
  setUp(() {
    api = _Api();
    repository = ApiProfessionalFieldsRepository(api);
  });

  test(
    'personal save rejects incomplete or duplicate languages and ignores late disposal results',
    () async {
      final draft = ProfileSetupController(
        fieldsRepository: repository,
        lookupsRepository: ApiProfileLookupsRepository(api),
        stepsRepository: ApiOnboardingStepsRepository(api),
      );
      await draft.loadFields();
      draft.chooseField(draft.fields.first);
      await draft.saveProfessionalField();
      draft.formFields = {'languages'};
      await draft.loadRelevantLookups();
      draft.languages.first.language = '9';
      expect(await draft.savePersonalInformation(), isFalse);
      expect(draft.personalFailure?.message, 'profile_language_incomplete');
      draft.languages.first.level = 'b1';
      draft.languages.add(LanguageEntry(2, language: '9', level: 'native'));
      expect(await draft.savePersonalInformation(), isFalse);
      expect(draft.personalFailure?.message, 'profile_languages_duplicate');
      expect(api.personalSaves, 0);
      draft.languages.removeLast();
      api.personalGate = Completer<void>();
      final pending = draft.savePersonalInformation();
      expect(draft.savingPersonalInfo, isTrue);
      draft.dispose();
      api.personalGate!.complete();
      expect(await pending, isFalse);
    },
  );

  test(
    'form fields use the selected server ID and reject malformed responses',
    () async {
      expect((await repository.formFields(42)).getOrThrow(), {
        'full_name',
        'email',
      });
      expect(api.formQuery, {'professional_field_id': 42});
      for (final raw in [
        null,
        {'success': false},
        {
          'success': true,
          'data': [1],
        },
        {
          'success': true,
          'data': [''],
        },
      ]) {
        api.formResponse = raw;
        expect((await repository.formFields(42)).isError, isTrue);
      }
    },
  );

  test(
    'failed form fields stay retryable and a new selection clears the schema',
    () async {
      final draft = ProfileSetupController(fieldsRepository: repository);
      addTearDown(draft.dispose);
      await draft.loadFields();
      draft.chooseField(draft.fields.first);
      api.formFailure = const NetworkFailure(message: 'offline');
      expect(await draft.saveProfessionalField(), isFalse);
      expect(draft.fieldFailure?.message, 'offline');
      expect(draft.formFields, isNull);
      api.formFailure = null;
      expect(await draft.saveProfessionalField(), isTrue);
      expect(draft.showsField('full_name'), isTrue);
      expect(draft.showsField('cv'), isFalse);
      draft.chooseField(draft.fields.last);
      expect(draft.formFields, isNull);
      expect(await draft.saveProfessionalField(), isTrue);
      expect(api.formQuery, {'professional_field_id': 42});
    },
  );

  test(
    'server IDs and ordering are preserved, inactive fields excluded',
    () async {
      final fields = (await repository.load()).getOrThrow();
      expect(api.loadedPath, '/talent/master-data/professional-fields');
      expect(fields.map((f) => f.id), [5, 3, 42]);
      expect(fields.last.name, 'Product Strategy');
      expect(fields.last.slug, 'field-42');
      expect(fields.last.jobs, isEmpty);
      expect((await repository.select(fields[1].id!)).isSuccess, isTrue);
      expect(api.savedPath, '/talent/onboarding/professional-field');
      expect(api.savedBody, {'professional_field_id': 3});
    },
  );

  test(
    'malformed, duplicate and unsuccessful responses cannot advance',
    () async {
      for (final response in [
        null,
        {'success': false},
        {'success': true, 'data': {}},
        {
          'success': true,
          'data': [
            {'id': 5},
          ],
        },
        {
          'success': true,
          'data': [field(1, 'One'), field(1, 'Two')],
        },
      ]) {
        api.response = response;
        expect((await repository.load()).isError, isTrue);
      }
      api.patchResponse = {'success': false};
      expect((await repository.select(3)).isError, isTrue);
      expect((await repository.select(0)).isError, isTrue);
    },
  );

  test(
    'no default live selection, failed save stays retryable and duplicates blocked',
    () async {
      final draft = ProfileSetupController(fieldsRepository: repository);
      addTearDown(draft.dispose);
      await draft.loadFields();
      expect(draft.selectedField, isNull);
      expect(await draft.saveProfessionalField(), isFalse);
      expect(api.saves, 0);
      draft.chooseField(draft.fields[1]);
      api.gate = Completer<void>();
      api.saveFailure = const ServerFailure(message: 'Please retry');
      final pending = draft.saveProfessionalField();
      expect(await draft.saveProfessionalField(), isFalse);
      draft.chooseField(draft.fields.first);
      expect(draft.selectedField?.id, 3);
      api.gate!.complete();
      expect(await pending, isFalse);
      expect(api.saves, 1);
      expect(draft.fieldFailure?.message, 'Please retry');
      api.saveFailure = null;
      expect(await draft.saveProfessionalField(), isTrue);
      expect(draft.fieldFailure, isNull);
      expect(api.savedBody, {'professional_field_id': 3});
    },
  );

  test(
    'load can retry and late results after disposal do not notify',
    () async {
      final draft = ProfileSetupController(fieldsRepository: repository);
      api.loadFailure = const NetworkFailure(message: 'offline');
      await draft.loadFields();
      expect(draft.fields, isEmpty);
      expect(draft.fieldFailure?.message, 'offline');
      api.loadFailure = null;
      api.gate = Completer<void>();
      final pending = draft.loadFields();
      draft.dispose();
      api.gate!.complete();
      await pending;
    },
  );

  testWidgets(
    'live cards support odd counts, errors and save-before-navigation in Arabic',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPreferencesImpl(await SharedPreferences.getInstance());
      await prefs.saveToken('access');
      await EasyLocalization.ensureInitialized();
      await initServiceLocator(preferencesOverride: prefs);
      await sl.unregister<ApiConsumer>();
      sl.registerSingleton<ApiConsumer>(api);
      api.loadFailure = const NetworkFailure(message: 'offline');
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [englishLocale, arabicLocale],
          path: assetPathLanguage,
          startLocale: arabicLocale,
          saveLocale: false,
          assetLoader: const _Translations(),
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, _) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const ProfileSetupView(
                seed: ProfileSetupSeed(
                  name: 'Demo Talent',
                  email: 'talent@example.test',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('offline'), findsOneWidget);
      api.loadFailure = null;
      await tester.tap(find.widgetWithText(TextButton, 'auth_retry'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('Product Strategy'), findsOneWidget);
      Future<void> next() async {
        final button = find.widgetWithText(
          ElevatedButton,
          'profile_continue'.tr(),
        );
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      final button = find.widgetWithText(
        ElevatedButton,
        'profile_continue'.tr(),
      );
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      await tester.ensureVisible(find.text('Product Strategy'));
      await tester.tap(find.text('Product Strategy'));
      api.saveFailure = const ServerFailure(message: 'Please retry');
      await next();
      expect(find.byType(BasicInfoStep), findsNothing);
      expect(find.text('Please retry'), findsOneWidget);
      api.saveFailure = null;
      await next();
      expect(find.byType(BasicInfoStep), findsOneWidget);
      expect(api.savedBody, {'professional_field_id': 42});
      expect(api.formQuery, {'professional_field_id': 42});
      final step = tester.widget<BasicInfoStep>(find.byType(BasicInfoStep));
      expect(step.draft.showsField('full_name'), isTrue);
      expect(step.draft.showsField('date_of_birth'), isFalse);
      expect(find.byType(TextFormField), findsNWidgets(2));
      final nextButton = find.widgetWithText(
        ElevatedButton,
        'profile_next'.tr(),
      );
      expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNotNull);
      step.draft.formFields = {
        'gender',
        'religion',
        'nationality_country_id',
        'residence_country_id',
        'residence_city_id',
        'languages',
        'expected_salary',
      };
      await step.draft.loadRelevantLookups();
      await tester.pumpAndSettle();
      Future<void> chooseLookup(String label, String option) async {
        final lookup = find.byWidgetPredicate(
          (w) => w is ProfileLookupSelect && w.label == label,
        );
        final dropdown = find.descendant(
          of: lookup,
          matching: find.byType(DropdownButtonFormField<String>),
        );
        await tester.ensureVisible(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text(option).last);
        await tester.pumpAndSettle();
      }

      await chooseLookup('Gender', 'Male');
      expect(step.draft.value('gender'), 'male');
      await chooseLookup('Religion', 'Islam');
      expect(step.draft.value('religion'), 'islam');
      await chooseLookup('Country', 'Egypt');
      expect(step.draft.value('country'), '7');
      expect(api.cityQuery, {'country_id': 7});
      expect(step.draft.options(ProfileLookup.cities), isEmpty);
      await chooseLookup('Language', 'Arabic');
      expect(step.draft.languages.first.language, '9');
      await chooseLookup('Proficiency', 'B1 - Intermediate');
      expect(step.draft.languages.first.level, 'b1');
      step.draft.formFields = {
        ...step.draft.formFields!,
        'full_name',
        'phone_number',
        'whatsapp_number',
        'cv',
      };
      step.draft.text('phoneCountryCode').text = '+20';
      step.draft.text('whatsappCountryCode').text = '+20';
      step.draft.text('phone').text = '1012345678';
      step.draft.text('whatsapp').text = '1012345678';
      step.draft.cv = PlatformFile(
        name: 'cv.pdf',
        size: 4,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      step.draft.refresh();
      await tester.pumpAndSettle();
      Future<void> savePersonal() async {
        await tester.ensureVisible(nextButton);
        await tester.pumpAndSettle();
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
      }

      api.personalSaveFailure = const ServerFailure(
        message: 'Please retry saving',
      );
      await savePersonal();
      expect(find.byType(BasicInfoStep), findsOneWidget);
      expect(find.text('Please retry saving'), findsOneWidget);
      expect(api.personalSaves, 1);
      final body = Map.fromEntries(api.personalBody!.fields);
      expect(body['professional_field_id'], '42');
      expect(body['phone_country_code'], '+20');
      expect(body['languages[0][language_id]'], '9');
      expect(body['languages[0][proficiency_level]'], 'b1');
      expect(body['email'], isNull);
      expect(api.personalBody!.files.single.key, 'cv');
      api.personalSaveFailure = null;
      api.personalGate = Completer<void>();
      await tester.tap(nextButton);
      await tester.pump();
      expect(find.byType(BasicInfoStep), findsOneWidget);
      expect(step.draft.savingPersonalInfo, isTrue);
      expect(await step.draft.savePersonalInformation(), isFalse);
      expect(api.personalSaves, 2);
      api.personalGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SkillsExperienceStep), findsOneWidget);
      expect(step.draft.savingPersonalInfo, isFalse);
      List<String> sections() => tester
          .widgetList<ProfileSection>(find.byType(ProfileSection))
          .map((section) => section.title)
          .toList();
      // Exercise rendering directly; connected navigation still requires saved steps.
      step.draft.formFields = {
        'professional_summary',
        'portfolio_url',
        'experiences',
      };
      step.draft.go(2);
      await tester.pumpAndSettle();
      expect(sections(), [
        'Professional Summary',
        'Portfolio & Social Links',
        'Work Experience',
      ]);
      expect(
        find.byWidgetPredicate(
          (w) => w is ProfileInput && w.label == 'LinkedIn',
        ),
        findsNothing,
      );
      step.draft.formFields = {'tool_ids'};
      step.draft.refresh();
      await tester.pumpAndSettle();
      expect(sections(), ['Technical Information']);
      expect(find.byType(ProfileLookupMultiSelect), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      step.draft.formFields = {'industry_ids'};
      step.draft.refresh();
      await tester.pumpAndSettle();
      expect(sections(), ['Technical Information']);
      expect(
        find.byWidgetPredicate(
          (w) => w is ProfileLookupMultiSelect && w.label == 'Industries',
        ),
        findsOneWidget,
      );
      for (final link in {
        'github_url': 'GitHub',
        'behance_url': 'Behance',
      }.entries) {
        step.draft.formFields = {link.key};
        step.draft.refresh();
        await tester.pumpAndSettle();
        expect(sections(), ['Portfolio & Social Links']);
        expect(
          find.byWidgetPredicate(
            (w) => w is ProfileInput && w.label == link.value,
          ),
          findsOneWidget,
        );
        expect(find.byType(TextFormField), findsOneWidget);
      }
      step.draft.formFields = {'expected_salary'};
      step.draft.go(3);
      await tester.pumpAndSettle();
      expect(sections(), ['Salary Details']);
      expect(find.byType(TextFormField), findsNWidgets(2));
      await chooseLookup('', 'GBP — British Pound');
      expect(step.draft.value('expectedCurrency'), '27');
      step.draft.formFields = {
        'industry_ids',
        'work_types',
        'work_modes',
        'notice_period_days',
        'willing_to_relocate',
      };
      step.draft.refresh();
      await tester.pumpAndSettle();
      expect(sections(), ['Work Info']);
      expect(
        find.byWidgetPredicate(
          (w) => w is ProfileSelect && w.label == 'Industries',
        ),
        findsNothing,
      );
      expect(find.byType(ProfileChoices), findsOneWidget);
      expect(find.byType(ProfileLookupMultiSelect), findsNWidgets(2));
      step.draft.formFields = {};
      step.draft.refresh();
      await tester.pumpAndSettle();
      expect(sections(), isEmpty);
      step.draft.formFields = {
        'professional_summary',
        'job_title_id',
        'seniority_level',
        'years_of_experience',
        'skill_ids',
        'tool_ids',
        'industry_ids',
        'linkedin_url',
        'projects',
        'experiences',
        'work_types',
        'work_modes',
        'notice_period_days',
        'current_salary',
        'expected_salary',
        'willing_to_relocate',
      };
      await step.draft.loadRelevantLookups();
      step.draft.go(2);
      await tester.pumpAndSettle();
      await chooseLookup('Job Title', 'Backend Engineer');
      await chooseLookup('Level', 'Mid Level');
      step.draft.text('years').text = '5';
      step.draft.text('LinkedIn').text = 'https://linkedin.com/in/example';
      Future<void> chooseChip(String label) async {
        final chip = find.widgetWithText(FilterChip, label);
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }

      await chooseChip('Dart');
      await chooseChip('Flutter');
      await chooseChip('VS Code');
      await chooseChip('Technology');
      api.detailsFailure = const ServerFailure(message: 'Details not saved');
      await savePersonal();
      expect(find.byType(SkillsExperienceStep), findsOneWidget);
      expect(find.text('Details not saved'), findsOneWidget);
      api.detailsFailure = null;
      await savePersonal();
      final skills = Map.fromEntries(api.skillsBody!.fields);
      expect(skills['job_title_id'], '52');
      expect(skills['skill_ids[0]'], '8');
      expect(skills['skill_ids[1]'], '3');
      expect(skills['industry_ids[0]'], '20');
      expect(step.draft.step, 3);
      await chooseChip('Full Time');
      await chooseChip('Part Time');
      await chooseChip('Remote');
      await chooseChip('Hybrid');
      step.draft.text('noticeDays').text = '30';
      step.draft.text('currentSalary').text = '15000';
      step.draft.text('minSalary').text = '20000';
      step.draft.text('maxSalary').text = '30000';
      step.draft.select('currentCurrency', '27');
      step.draft.select('expectedCurrency', '27');
      step.draft.select('relocate', 'No');
      await tester.pumpAndSettle();
      final saveButton = find.widgetWithText(
        ElevatedButton,
        'profile_save_profile'.tr(),
      );
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      expect(api.workBody, {
        'work_types': ['full_time', 'part_time'],
        'work_modes': ['remote', 'hybrid'],
        'notice_period_days': 30,
        'current_salary': 15000,
        'current_currency_id': 27,
        'expected_salary_min': 20000,
        'expected_salary_max': 30000,
        'expected_currency_id': 27,
        'willing_to_relocate': false,
      });
      expect(find.text('profile_profile_saved'.tr()), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await sl.reset();
    },
  );
}
