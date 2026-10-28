import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/profile_setup/data/repositories/api_profile_lookups_repository.dart';
import 'package:qader/features/profile_setup/domain/repositories/profile_lookups_repository.dart';
import 'package:qader/features/profile_setup/presentation/profile_setup_controller.dart';
import 'package:qader/features/profile_setup/domain/repositories/professional_fields_repository.dart';

class _Api extends Fake implements ApiConsumer {
  Object? response;
  String? path;
  Map<String, dynamic>? query;
  int calls = 0;
  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    calls++;
    this.path = path;
    query = queryParameters;
    return Right(fromJson(response));
  }
}

class _Fields extends Fake implements ProfessionalFieldsRepository {}

class _Lookups extends Fake implements ProfileLookupsRepository {
  final requested = <ProfileLookup>[];
  final cityRequests =
      <int, Completer<Either<Failure, List<ProfileLookupOption>>>>{};
  bool fail = false;
  @override
  Future<Either<Failure, List<ProfileLookupOption>>> load(
    ProfileLookup lookup, {
    int? countryId,
    String? search,
    int? professionalFieldId,
  }) async {
    requested.add(lookup);
    if (lookup == ProfileLookup.cities) {
      return cityRequests.putIfAbsent(countryId!, Completer.new).future;
    }
    return fail
        ? const Left(NetworkFailure(message: 'offline'))
        : const Right([
            ProfileLookupOption(value: 7, label: 'Country A'),
            ProfileLookupOption(value: 16, label: 'Country B'),
          ]);
  }
}

void main() {
  test(
    'profession filters and enum endpoint names match the exported API',
    () async {
      final api = _Api();
      final repository = ApiProfileLookupsRepository(api);
      api.response = {
        'success': true,
        'data': [
          {'id': 52, 'name': 'Backend Engineer'},
        ],
      };
      for (final lookup in [
        ProfileLookup.jobTitles,
        ProfileLookup.skills,
        ProfileLookup.tools,
      ]) {
        expect(
          (await repository.load(
            lookup,
            professionalFieldId: 42,
          )).getOrThrow().single.id,
          52,
        );
        expect(api.query, {'professional_field_id': 42});
        expect(api.path, '/talent/master-data/${lookup.endpoint}');
      }
      api.response = {
        'success': true,
        'data': [
          {'value': 'mid_level', 'label': 'Mid Level'},
        ],
      };
      for (final lookup in [
        ProfileLookup.seniorityLevels,
        ProfileLookup.workTypes,
        ProfileLookup.workModes,
      ]) {
        expect(
          (await repository.load(lookup)).getOrThrow().single.key,
          'mid_level',
        );
        expect(api.path, '/talent/master-data/${lookup.endpoint}');
      }
    },
  );

  test(
    'changing the professional field invalidates scoped choices and IDs',
    () async {
      final api = _Api();
      api.response = {
        'success': true,
        'data': [
          {'id': 52, 'name': 'Backend Engineer'},
        ],
      };
      final draft = ProfileSetupController(
        fieldsRepository: _Fields(),
        lookupsRepository: ApiProfileLookupsRepository(api),
      );
      addTearDown(draft.dispose);
      draft.fields = [
        const ProfessionalField('A', '', [], id: 42),
        const ProfessionalField('B', '', [], id: 3),
      ];
      draft.chooseField(draft.fields.first);
      draft.formFields = {'job_title_id', 'skill_ids', 'tool_ids'};
      await draft.loadRelevantLookups();
      expect(api.query, {'professional_field_id': 42});
      draft.select('job', '52');
      draft.selectValues('skill_ids', {'52'});
      draft.selectValues('tool_ids', {'52'});
      draft.chooseField(draft.fields.last);
      expect(draft.formFields, isNull);
      expect(draft.value('job'), isNull);
      expect(draft.selectedValues('skill_ids'), isEmpty);
      expect(draft.selectedValues('tool_ids'), isEmpty);
      expect(draft.options(ProfileLookup.jobTitles), isEmpty);
      draft.formFields = {'job_title_id'};
      await draft.loadRelevantLookups();
      expect(api.query, {'professional_field_id': 3});
    },
  );

  test(
    'language proficiencies retain API codes and load only with languages',
    () async {
      final api = _Api();
      final repo = ApiProfileLookupsRepository(api);
      const labels = {
        'a1': 'A1 - Beginner',
        'a2': 'A2 - Elementary',
        'b1': 'B1 - Intermediate',
        'b2': 'B2 - Upper Intermediate',
        'c1': 'C1 - Advanced',
        'c2': 'C2 - Proficient',
        'native': 'Native',
      };
      api.response = {
        'success': true,
        'data': [
          for (final entry in labels.entries)
            {'value': entry.key, 'label': entry.value},
        ],
      };
      final options = (await repo.load(
        ProfileLookup.languageProficiencies,
      )).getOrThrow();
      expect(api.path, '/talent/master-data/language-proficiencies');
      expect(api.query, isNull);
      expect(options.map((o) => o.key), labels.keys);
      expect(options.map((o) => o.label), labels.values);
      final lookups = _Lookups();
      final draft = ProfileSetupController(
        fieldsRepository: _Fields(),
        lookupsRepository: lookups,
      );
      addTearDown(draft.dispose);
      draft.formFields = {'email'};
      await draft.loadRelevantLookups();
      expect(lookups.requested, isEmpty);
      draft.formFields = {'languages'};
      await draft.loadRelevantLookups();
      expect(lookups.requested.toSet(), {
        ProfileLookup.languages,
        ProfileLookup.languageProficiencies,
      });
    },
  );

  test(
    'enum values, real IDs, inactive filtering and duplicate labels',
    () async {
      final api = _Api();
      final repo = ApiProfileLookupsRepository(api);
      api.response = {
        'success': true,
        'data': [
          {'value': 'prefer_not_to_say', 'label': 'Prefer not to say'},
          {'value': 'islam', 'label': 'Islam'},
        ],
      };
      final religions = (await repo.load(ProfileLookup.religions)).getOrThrow();
      expect(api.path, '/talent/master-data/religions');
      expect(religions.map((o) => o.key), ['prefer_not_to_say', 'islam']);
      expect(religions.last.label, 'Islam');
      expect(religions.last.id, isNull);
      api.response = {
        'success': true,
        'data': [
          {'id': 42, 'name': 'Same name', 'is_active': true},
          {'id': 5, 'name': 'Same name', 'is_active': true},
          {'id': 3, 'name': 'Hidden', 'is_active': false},
        ],
      };
      for (final lookup in [
        ProfileLookup.countries,
        ProfileLookup.languages,
        ProfileLookup.cities,
      ]) {
        final options = (await repo.load(lookup, countryId: 16)).getOrThrow();
        expect(options.map((o) => o.id), [42, 5]);
        expect(options.map((o) => o.label), ['Same name', 'Same name']);
      }
      expect(api.query, {'country_id': 16});
      api.response = {
        'success': true,
        'data': [
          {
            'id': 17,
            'name': 'British Pound',
            'code': 'GBP',
            'symbol': '£',
            'is_active': true,
          },
        ],
      };
      final currency = (await repo.load(
        ProfileLookup.currencies,
        search: ' b ',
      )).getOrThrow().single;
      expect(currency.id, 17);
      expect(currency.label, 'GBP — British Pound');
      expect(api.query, {'search': 'b'});
    },
  );

  test('empty results are valid; malformed and duplicate IDs fail', () async {
    final api = _Api();
    final repo = ApiProfileLookupsRepository(api);
    api.response = {'success': true, 'data': []};
    expect(
      (await repo.load(ProfileLookup.cities, countryId: 16)).getOrThrow(),
      isEmpty,
    );
    final before = api.calls;
    expect((await repo.load(ProfileLookup.cities)).isError, isTrue);
    expect(api.calls, before);
    for (final raw in [
      null,
      {'success': false},
      {'success': true, 'data': {}},
      {
        'success': true,
        'data': [
          {'id': '1', 'name': 'Egypt'},
        ],
      },
      {
        'success': true,
        'data': [
          {'id': 1, 'name': 'Egypt', 'is_active': 'yes'},
        ],
      },
      {
        'success': true,
        'data': [
          {'id': 1, 'name': 'A'},
          {'id': 1, 'name': 'B'},
        ],
      },
    ]) {
      api.response = raw;
      expect((await repo.load(ProfileLookup.countries)).isError, isTrue);
    }
  });

  test(
    'only visible lists load, cache is reused, failures can retry',
    () async {
      final repo = _Lookups();
      final draft = ProfileSetupController(
        fieldsRepository: _Fields(),
        lookupsRepository: repo,
      );
      addTearDown(draft.dispose);
      draft.formFields = {
        'gender',
        'religion',
        'nationality_country_id',
        'residence_country_id',
      };
      repo.fail = true;
      await draft.loadRelevantLookups();
      expect(repo.requested.toSet(), {
        ProfileLookup.genders,
        ProfileLookup.religions,
        ProfileLookup.countries,
      });
      expect(draft.lookupFailures.length, 3);
      repo.fail = false;
      await draft.loadRelevantLookups();
      expect(draft.lookupFailures, isEmpty);
      final count = repo.requested.length;
      await draft.loadRelevantLookups();
      expect(repo.requested.length, count);
      expect(draft.lookupId(ProfileLookup.countries, '16'), 16);
      expect(draft.lookupId(ProfileLookup.countries, '0'), isNull);
    },
  );

  test(
    'country changes clear cities and reject stale requests and disposal callbacks',
    () async {
      final repo = _Lookups();
      final draft = ProfileSetupController(
        fieldsRepository: _Fields(),
        lookupsRepository: repo,
      );
      draft.formFields = {'residence_country_id', 'residence_city_id'};
      await draft.loadRelevantLookups();
      draft.select('city', 'old');
      final a = draft.selectResidenceCountry('7');
      expect(draft.value('city'), isNull);
      final b = draft.selectResidenceCountry('16');
      repo.cityRequests[16]!.complete(
        const Right([ProfileLookupOption(value: 82, label: 'B city')]),
      );
      await b;
      repo.cityRequests[7]!.complete(
        const Left(NetworkFailure(message: 'old country error')),
      );
      await a;
      expect(draft.options(ProfileLookup.cities).single.id, 82);
      expect(draft.lookupFailures, isEmpty);
      expect(draft.lookupLoading, isEmpty);
      draft.select('city', '82');
      await draft.selectResidenceCountry(null);
      expect(draft.value('city'), isNull);
      expect(draft.options(ProfileLookup.cities), isEmpty);
      repo.cityRequests.remove(7);
      final pending = draft.selectResidenceCountry('7');
      draft.dispose();
      repo.cityRequests[7]!.complete(const Right([]));
      await pending;
    },
  );
}
