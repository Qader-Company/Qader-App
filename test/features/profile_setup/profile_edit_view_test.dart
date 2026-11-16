import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/core/resources/theme_manager.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/profile_setup/data/repositories/api_profile_edit_repository.dart';
import 'package:qader/features/profile_setup/domain/entities/profile_lookup.dart';
import 'package:qader/features/profile_setup/domain/repositories/onboarding_steps_repository.dart';
import 'package:qader/features/profile_setup/domain/repositories/professional_fields_repository.dart';
import 'package:qader/features/profile_setup/domain/repositories/profile_edit_repository.dart';
import 'package:qader/features/profile_setup/domain/repositories/profile_lookups_repository.dart';
import 'package:qader/features/profile_setup/presentation/view/profile_setup_view.dart';

/// Copy of a real `GET /talent/profile` test-env response (Apidog), with
/// the CV file renamed.
Map<String, dynamic> _profile() => {
  'success': true,
  'data': {
    'id': 1,
    'sections': [
      {
        'key': 'personal-information',
        'visible_fields': [
          'professional_field_id',
          'full_name',
          'email',
          'phone_number',
          'whatsapp_number',
          'date_of_birth',
          'gender',
          'religion',
          'nationality_country_id',
          'residence_country_id',
          'residence_city_id',
          'languages',
          'cv',
        ],
        'required_fields': [
          'professional_field_id',
          'full_name',
          'email',
          'phone_number',
          'whatsapp_number',
          'gender',
          'cv',
        ],
        'conditional_required_fields': <Object?>[],
        'data': {
          'professional_field': {'id': 1, 'name': 'Software Development'},
          'full_name': 'Demo Talent',
          'email': 'talent@qader.test',
          'phone_country_code': '+20',
          'phone_number': '1012345678',
          'whatsapp_country_code': '+20',
          'whatsapp_number': '1012345678',
          'date_of_birth': '1995-05-20',
          'gender': 'male',
          'religion': 'islam',
          'nationality_country': {'id': 1, 'name': 'Egypt', 'code': 'EG'},
          'residence_country': {'id': 1, 'name': 'Egypt', 'code': 'EG'},
          'residence_city': {'id': 1, 'name': 'Cairo'},
          'languages': [
            {'id': 1, 'name': 'Arabic', 'proficiency_level': 'a1'},
          ],
          'cv': {
            'id': 2,
            'name': 'Demo_Talent_CV',
            'file_name': 'Demo_Talent_CV.pdf',
            'mime_type': 'application/pdf',
            'size': '126925',
          },
        },
      },
      {
        'key': 'skills-and-experiences',
        'visible_fields': [
          'professional_summary',
          'job_title_id',
          'seniority_level',
          'years_of_experience',
          'skill_ids',
          'tool_ids',
          'linkedin_url',
          'github_url',
          'portfolio_url',
          'experiences',
          'projects',
          'industry_ids',
        ],
        'required_fields': [
          'job_title_id',
          'seniority_level',
          'years_of_experience',
          'skill_ids',
          'linkedin_url',
          'industry_ids',
          'experiences',
        ],
        'conditional_required_fields': <Object?>[],
        'data': {
          'professional_summary':
              'Backend engineer experienced in building scalable APIs.',
          'job_title': {'id': 3, 'name': 'Backend Developer'},
          'seniority_level': 'mid_level',
          'years_of_experience': '5',
          'skills': [
            {'id': 3, 'name': 'JavaScript'},
          ],
          'industries': [
            {
              'id': 2,
              'slug': 'financial-services',
              'name': 'Financial Services',
            },
          ],
          'tools': <Object?>[],
          'experiences': [
            {
              'id': 4,
              'job_title': 'Backend Engineer',
              'company_name': 'Qader',
              'company_url': 'https://qader.example.com',
              'started_at': '2022-01-01',
              'ended_at': '2023-01-01',
              'currently_working': false,
              'responsibilities':
                  'Designed APIs and maintained backend services.',
              'display_order': '1',
            },
          ],
          'linkedin_url': 'http://bailey.com/',
          'github_url': 'http://rempel.com/sunt-nihil',
          'portfolio_url': 'http://www.dare.org/iure-odit',
          'projects': [
            {
              'id': 4,
              'name': 'Qader Platform',
              'description': 'Talent registration platform.',
              'url': 'https://project.example.com',
              'display_order': '1',
              'images': <Object?>[],
            },
          ],
        },
      },
      {
        'key': 'work-preferences',
        'visible_fields': [
          'work_types',
          'work_modes',
          'willing_to_relocate',
          'notice_period_days',
          'current_salary',
          'expected_salary',
        ],
        'required_fields': [
          'work_types',
          'work_modes',
          'notice_period_days',
          'current_salary',
          'expected_salary',
        ],
        'conditional_required_fields': <Object?>[],
        'data': {
          'work_types': ['full_time', 'part_time'],
          'work_modes': ['hybrid', 'remote'],
          'willing_to_relocate': true,
          'notice_period_days': '30',
          'current_salary': '15000.00',
          'current_currency': {
            'id': 1,
            'name': 'Egyptian Pound',
            'code': 'EGP',
          },
          'expected_salary_min': '20000.00',
          'expected_salary_max': '30000.00',
          'expected_currency': {
            'id': 1,
            'name': 'Egyptian Pound',
            'code': 'EGP',
          },
        },
      },
    ],
  },
};

class _Api extends Fake implements ApiConsumer {
  final patches = <Map<String, dynamic>>[];

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async => Right(fromJson(_profile()));

  @override
  Future<Either<Failure, T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic json) fromJson,
  }) async {
    patches.add(Map<String, dynamic>.from(data as Map));
    return Right(fromJson(_profile()));
  }
}

class _Preferences extends Fake implements AppPreferences {
  @override
  final ValueNotifier<int> sessionRevision = ValueNotifier(0);
  @override
  bool get isLoggedIn => true;
}

class _Fields extends Fake implements ProfessionalFieldsRepository {}

class _Steps extends Fake implements OnboardingStepsRepository {}

class _Lookups extends Fake implements ProfileLookupsRepository {
  static const _options = <ProfileLookup, List<(Object, String)>>{
    ProfileLookup.genders: [('male', 'Male'), ('female', 'Female')],
    ProfileLookup.religions: [('islam', 'Islam')],
    ProfileLookup.countries: [(1, 'Egypt')],
    ProfileLookup.cities: [(1, 'Cairo')],
    ProfileLookup.languages: [(1, 'Arabic')],
    ProfileLookup.languageProficiencies: [('a1', 'A1')],
    ProfileLookup.currencies: [(1, 'EGP')],
    ProfileLookup.jobTitles: [(3, 'Backend Developer')],
    ProfileLookup.skills: [(3, 'JavaScript')],
    ProfileLookup.tools: [(7, 'Git')],
    ProfileLookup.industries: [(2, 'Financial Services')],
    ProfileLookup.seniorityLevels: [('mid_level', 'Mid Level')],
    ProfileLookup.workTypes: [
      ('full_time', 'Full Time'),
      ('part_time', 'Part Time'),
    ],
    ProfileLookup.workModes: [
      ('on_site', 'On Site'),
      ('remote', 'Remote'),
      ('hybrid', 'Hybrid'),
    ],
  };

  @override
  Future<Either<Failure, List<ProfileLookupOption>>> load(
    ProfileLookup lookup, {
    int? countryId,
    int? professionalFieldId,
    String? search,
  }) async => Right([
    for (final (value, label) in _options[lookup] ?? const <(Object, String)>[])
      ProfileLookupOption(value: value, label: label),
  ]);
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
  testWidgets('edit profile walks the three prefilled steps and saves each', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final family in ['Poppins', 'Rubik']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();

    final api = _Api();
    final captureKey = GlobalKey();
    bool? popped;
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: EasyLocalization(
          supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
          startLocale: const Locale('en', 'US'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: const _Translations(),
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AppPreferences>.value(value: _Preferences()),
              RepositoryProvider<ProfessionalFieldsRepository>.value(
                value: _Fields(),
              ),
              RepositoryProvider<ProfileLookupsRepository>.value(
                value: _Lookups(),
              ),
              RepositoryProvider<OnboardingStepsRepository>.value(
                value: _Steps(),
              ),
              RepositoryProvider<ProfileEditRepository>.value(
                value: ApiProfileEditRepository(api),
              ),
            ],
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (context, _) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: ThemeManager.getTheme(context.locale),
                home: Builder(
                  builder: (context) => Center(
                    child: TextButton(
                      onPressed: () async {
                        popped = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileSetupView(edit: true),
                          ),
                        );
                      },
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    Future<void> capture(String name, double height) async {
      tester.view.physicalSize = Size(390, height);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/design_review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    Future<void> next(String label) async {
      final button = find.widgetWithText(ElevatedButton, label);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Basic Info'), findsOneWidget);
    expect(find.text('Demo_Talent_CV.pdf'), findsOneWidget);
    await capture('profile_edit_basic', 1900);
    await next('Next');
    expect(api.patches.single.keys, ['personal-information']);

    expect(find.text('Skills & Experience'), findsOneWidget);
    await capture('profile_edit_skills', 2800);
    await next('Next');
    expect(api.patches.last.keys, ['skills-and-experiences']);

    expect(find.text('Work Preferences'), findsOneWidget);
    await capture('profile_edit_work', 1200);
    await next('Save Profile');
    expect(api.patches.last.keys, ['work-preferences']);
    expect(api.patches, hasLength(3));
    expect(popped, isTrue);
  });
}
