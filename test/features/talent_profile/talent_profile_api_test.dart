import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/talent_profile/data/repositories/api_talent_profile_repository.dart';
import 'package:qader/features/talent_profile/domain/entities/talent_profile.dart';
import 'package:qader/features/talent_profile/domain/repositories/talent_profile_repository.dart';
import 'package:qader/features/talent_profile/presentation/cubit/talent_profile_cubit.dart';
import 'package:qader/features/talent_profile/presentation/view/talent_profile_view.dart';

/// Copy of a real `GET /talent/profile` test-env response (Apidog), with
/// lists trimmed and the CV file renamed.
Map<String, dynamic> _response() => {
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
        'required_fields': ['full_name', 'email'],
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
            'download_url':
                'https://test.api.qadereg.com/api/v1/talent/profile/media/2/download',
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
        'required_fields': ['job_title_id'],
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
        'required_fields': ['work_types'],
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
  _Api(this.body);
  final Object? body;
  final paths = <String>[];

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    paths.add(path);
    return Right(fromJson(body));
  }
}

/// Returns queued results for `load()`, one per call.
class _Repo extends Fake implements TalentProfileRepository {
  _Repo(this.results);
  final List<Either<Failure, TalentProfile>> results;
  int loads = 0;

  @override
  Future<Either<Failure, TalentProfile>> load() async {
    loads++;
    return results.length > 1 ? results.removeAt(0) : results.single;
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

TalentProfile _profile() =>
    TalentProfile.fromJson(_response()['data'] as Map<String, dynamic>);

void main() {
  test('parses the three sections of the API response', () {
    final profile = _profile();
    expect(profile.name, 'Demo Talent');
    expect(profile.title, 'Backend Developer');
    expect(profile.email, 'talent@qader.test');
    expect(profile.phone, '+20 1012345678');
    expect(profile.whatsapp, '+20 1012345678');
    expect(profile.location, 'Cairo, Egypt');
    expect(profile.yearsOfExperience, 5);
    expect(profile.dateOfBirth, DateTime(1995, 5, 20));
    expect(profile.gender, 'male');
    expect(profile.religion, 'islam');
    expect(profile.nationality, 'Egypt');
    expect(profile.languages.single.name, 'Arabic');
    expect(profile.languages.single.level, 'a1');
    expect(profile.cvFileName, 'Demo_Talent_CV.pdf');
    expect(profile.skills, ['JavaScript']);
    expect(profile.tools, isEmpty);
    expect(profile.links.map((link) => link.kind), [
      ProfileLinkKind.linkedin,
      ProfileLinkKind.portfolio,
      ProfileLinkKind.github,
    ]);
    final experience = profile.experiences.single;
    expect(experience.title, 'Backend Engineer');
    expect(experience.company, 'Qader');
    expect(experience.start, DateTime(2022));
    expect(experience.end, DateTime(2023));
    expect(experience.current, isFalse);
    expect(profile.projects.single.url, 'https://project.example.com');
    expect(profile.workTypes, ['full_time', 'part_time']);
    expect(profile.workModes, ['hybrid', 'remote']);
    expect(profile.expectedSalary, '20,000–30,000 EGP');
    expect(profile.currentSalary, '15,000 EGP');
    expect(profile.noticePeriodDays, 30);
    expect(profile.willingToRelocate, isTrue);
    // Not part of this endpoint: the UI hides them.
    expect(profile.status, isNull);
    expect(profile.completion, isNull);
    expect(profile.available, isNull);
    expect(profile.shows('email'), isTrue);
    expect(profile.shows('not_a_field'), isFalse);
  });

  test('tolerates missing sections, nulls and unexpected types', () {
    final profile = TalentProfile.fromJson({
      'sections': [
        'junk',
        {'key': 'personal-information', 'data': null},
        {
          'key': 'skills-and-experiences',
          'data': {
            'job_title': null,
            'years_of_experience': 'many',
            'skills': [null, 3, <String, dynamic>{}],
            'experiences': [
              {'job_title': null},
            ],
            'linkedin_url': '',
          },
        },
        {
          'key': 'work-preferences',
          'data': {'work_types': 'full_time', 'current_salary': null},
        },
      ],
    });
    expect(profile.name, '');
    expect(profile.title, '');
    expect(profile.yearsOfExperience, isNull);
    expect(profile.skills, isEmpty);
    expect(profile.experiences, isEmpty);
    expect(profile.links, isEmpty);
    expect(profile.workTypes, isEmpty);
    expect(profile.currentSalary, '');
    expect(profile.visibleFields, isNull);
    expect(TalentProfile.fromJson(const {}).name, '');
  });

  test('repository reads /talent/profile and validates the shape', () async {
    final api = _Api(_response());
    final result = await ApiTalentProfileRepository(api).load();
    expect(api.paths, ['/talent/profile']);
    expect(result.getOrThrow().name, 'Demo Talent');

    for (final body in [
      null,
      'text',
      {'success': false, 'data': <String, dynamic>{}},
      {'success': true, 'data': null},
      {
        'success': true,
        'data': {'id': 1},
      },
    ]) {
      final invalid = await ApiTalentProfileRepository(_Api(body)).load();
      expect(invalid.getErrorOrThrow().message, 'talent_invalid_response');
    }
  });

  test('cubit keeps the last profile when a reload fails', () async {
    final repo = _Repo([
      Right(_profile()),
      const Left(NetworkFailure(message: 'offline')),
    ]);
    final cubit = TalentProfileCubit(repo);
    expect(cubit.state.loading, isTrue);
    await cubit.load();
    expect(cubit.state.profile?.name, 'Demo Talent');
    expect(cubit.state.failure, isNull);
    await cubit.load();
    expect(cubit.state.failure, isA<NetworkFailure>());
    expect(cubit.state.profile?.name, 'Demo Talent');
    await cubit.close();
  });

  Future<void> pump(WidgetTester tester, _Repo repo) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
        startLocale: const Locale('en', 'US'),
        saveLocale: false,
        path: 'assets/translations',
        assetLoader: const _Translations(),
        child: Builder(
          builder: (context) =>
              RepositoryProvider<TalentProfileRepository>.value(
                value: repo,
                child: MaterialApp(
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: const TalentProfileView(),
                ),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('live profile shows API data and no sample data', (tester) async {
    await pump(tester, _Repo([Right(_profile())]));
    expect(tester.takeException(), isNull);
    expect(find.text('Demo Talent'), findsOneWidget);
    expect(find.text('Backend Developer'), findsOneWidget);
    expect(find.text('Cairo, Egypt'), findsOneWidget);
    expect(find.text('5 Years Experience'), findsOneWidget);
    expect(find.text('Egypt'), findsNWidgets(2));
    expect(find.text('Islam'), findsOneWidget);
    expect(find.text('20/5/1995'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);
    // Fields this endpoint does not send stay hidden.
    expect(find.text('Accepted'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Muhamed Bayomee'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('profile_tab_1')));
    await tester.pumpAndSettle();
    expect(find.text('JavaScript'), findsOneWidget);
    expect(find.text('Tools'), findsNothing);
    expect(find.text('Backend Engineer'), findsOneWidget);
    expect(find.text('Jan 2022 - Jan 2023'), findsOneWidget);
    expect(find.text('Qader Platform'), findsNWidgets(2));

    // With the test font the last tab starts beyond the screen edge.
    await tester.ensureVisible(find.byKey(const ValueKey('profile_tab_2')));
    await tester.tap(find.byKey(const ValueKey('profile_tab_2')));
    await tester.pumpAndSettle();
    for (final label in ['Full Time', 'Part Time', 'Hybrid', 'Remote']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('20,000–30,000 EGP'), findsOneWidget);
    expect(find.text('15,000 EGP'), findsOneWidget);
    expect(find.text('30 Days'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('Demo_Talent_CV.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('load failure offers a retry that reloads', (tester) async {
    final repo = _Repo([
      const Left(NetworkFailure(message: 'offline')),
      Right(_profile()),
    ]);
    await pump(tester, repo);
    expect(find.text("We couldn't load your profile"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repo.loads, 2);
    expect(find.text('Demo Talent'), findsOneWidget);
  });

  testWidgets('changing the language reloads the profile', (tester) async {
    final repo = _Repo([Right(_profile())]);
    await pump(tester, repo);
    expect(repo.loads, 1);
    await tester
        .element(find.byType(TalentProfileView))
        .setLocale(const Locale('ar', 'SA'));
    await tester.pumpAndSettle();
    expect(repo.loads, 2);
    expect(tester.takeException(), isNull);
  });
}
