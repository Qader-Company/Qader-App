import 'dart:async';
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

/// A `GET /talent/profile` `data` object with the three sections, in the
/// shape of the Apidog example.
Map<String, dynamic> _data({
  Map<String, dynamic> personal = const {},
  Map<String, dynamic> skills = const {},
  Map<String, dynamic> work = const {},
  List<String>? personalVisible,
  List<String>? skillsVisible,
}) => {
  'sections': [
    {
      'key': 'personal-information',
      'visible_fields': ?personalVisible,
      'data': personal,
    },
    {
      'key': 'skills-and-experiences',
      'visible_fields': ?skillsVisible,
      'data': skills,
    },
    {'key': 'work-preferences', 'data': work},
  ],
};

class _Api extends Fake implements ApiConsumer {
  _Api(this.result);
  final Either<Failure, Object?> result;
  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async => result.fold(Left.new, (raw) => Right(fromJson(raw)));
}

class _Repo extends Fake implements TalentProfileRepository {
  _Repo(this.result);
  Either<Failure, TalentProfile> result;
  Completer<void>? gate;
  int loads = 0;
  @override
  Future<Either<Failure, TalentProfile>> load() async {
    loads++;
    await gate?.future;
    return result;
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
  group('TalentProfile.fromJson', () {
    test('experiences and projects follow display_order', () {
      final profile = TalentProfile.fromJson(
        _data(
          skills: {
            'experiences': [
              {'job_title': 'Third', 'display_order': 3},
              {'job_title': 'First', 'display_order': 1},
              {'job_title': 'No order'},
              {
                'job_title': 'Second',
                'display_order': '2',
                'currently_working': true,
                'started_at': '2024-02-01',
                'ended_at': null,
              },
            ],
            'projects': [
              {'name': 'B', 'display_order': 2},
              {'name': 'A', 'display_order': 1},
              {'name': '', 'display_order': 0},
            ],
          },
        ),
      );
      expect(profile.experiences.map((e) => e.title), [
        'No order',
        'First',
        'Second',
        'Third',
      ]);
      final current = profile.experiences[2];
      expect(current.current, isTrue);
      expect(current.start, DateTime(2024, 2));
      expect(current.end, isNull);
      // A project without a name is skipped.
      expect(profile.projects.map((p) => p.name), ['A', 'B']);
    });

    test('salaries are grouped, rounded and keep their currency', () {
      TalentProfile parse(Map<String, dynamic> work) =>
          TalentProfile.fromJson(_data(work: work));
      expect(
        parse({
          'expected_salary_min': '1200000.00',
          'expected_salary_max': 2500000,
          'expected_currency': {'code': 'EGP'},
        }).expectedSalary,
        '1,200,000–2,500,000 EGP',
      );
      // Only a minimum, no currency, decimals rounded.
      expect(parse({'expected_salary_min': '999.6'}).expectedSalary, '1,000');
      expect(
        parse({
          'current_salary': '750',
          'current_currency': {'code': 'USD'},
        }).currentSalary,
        '750 USD',
      );
      // Not a number: hidden.
      expect(parse({'current_salary': 'n/a'}).currentSalary, '');
    });

    test('phones, CV name, relocation and lookups tolerate gaps', () {
      final profile = TalentProfile.fromJson(
        _data(
          personal: {
            'phone_country_code': '+20',
            'phone_number': '  ',
            'whatsapp_number': '1000000000',
            'cv': {'name': 'cv.pdf'},
            'residence_city': {'name': 'Giza'},
            'residence_country': null,
          },
          work: {'willing_to_relocate': 'yes'},
        ),
      );
      expect(profile.phone, '+20');
      expect(profile.whatsapp, '1000000000');
      // `file_name` first, `name` as a fallback.
      expect(profile.cvFileName, 'cv.pdf');
      expect(profile.location, 'Giza');
      expect(profile.willingToRelocate, isNull);
    });

    test('visible_fields of every section add up', () {
      final profile = TalentProfile.fromJson(
        _data(personalVisible: ['email'], skillsVisible: ['skill_ids']),
      );
      expect(profile.visibleFields, {'email', 'skill_ids'});
      expect(profile.shows('email'), isTrue);
      expect(profile.shows('skill_ids'), isTrue);
      expect(profile.shows('phone_number'), isFalse);
    });

    test('copyWith changes only what it is given', () {
      final profile = TalentProfile.fromJson(
        _data(
          personal: {'full_name': 'Sara', 'email': 'sara@example.test'},
          skills: {
            'skills': [
              {'id': 1, 'name': 'Dart'},
            ],
          },
          personalVisible: ['email'],
        ),
      );
      final edited = profile.copyWith(
        name: 'Sara Ali',
        status: TalentProfileStatus.restricted,
      );
      expect(edited.name, 'Sara Ali');
      expect(edited.status, TalentProfileStatus.restricted);
      expect(edited.email, 'sara@example.test');
      expect(edited.skills, ['Dart']);
      expect(edited.visibleFields, {'email'});
    });
  });

  test('repository passes network failures through', () async {
    final result = await ApiTalentProfileRepository(
      _Api(const Left(NetworkFailure(message: 'offline'))),
    ).load();
    expect(result.getErrorOrThrow(), isA<NetworkFailure>());
  });

  test('a closed cubit ignores a late response', () async {
    final repo = _Repo(Right(TalentProfile.fromJson(_data())))
      ..gate = Completer();
    final cubit = TalentProfileCubit(repo);
    final load = cubit.load();
    await cubit.close();
    repo.gate!.complete();
    await load;
    expect(cubit.state.loading, isTrue);
  });

  testWidgets('the screen hides what visible_fields leaves out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final profile = TalentProfile.fromJson(
      _data(
        personal: {
          'full_name': 'Sara Ali',
          'email': 'sara@example.test',
          'phone_country_code': '+20',
          'phone_number': '1012345678',
        },
        // The backend shows the email but not the phone.
        personalVisible: ['full_name', 'email'],
      ),
    );
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
                value: _Repo(Right(profile)),
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
    expect(find.text('Sara Ali'), findsWidgets);
    // In the header and in the personal section.
    expect(find.text('sara@example.test'), findsNWidgets(2));
    // The personal section drops the phone row; the summary card keeps
    // the owner's own contact line.
    expect(find.text('Phone Number'), findsNothing);
    expect(find.text('+20 1012345678'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
