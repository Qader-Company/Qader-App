import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/offers/data/repositories/api_offers_repository.dart';
import 'package:qader/features/offers/domain/entities/hiring_offer_summary.dart';

/// Real `GET /talent/hiring-offers/options` test-env response (Apidog).
Map<String, dynamic> _options() => {
  'success': true,
  'data': {
    'item_statuses': [
      {'value': 'pending', 'label': 'Pending'},
      {'value': 'offer', 'label': 'Offer'},
      {'value': 'interview', 'label': 'Interview'},
      {'value': 'accepted', 'label': 'Accepted'},
      {'value': 'on_hold', 'label': 'On Hold'},
      {'value': 'rejected', 'label': 'Rejected'},
      {'value': 'cancelled', 'label': 'Cancelled'},
      {'value': 'completed', 'label': 'Completed'},
    ],
    'offer_statuses': [
      {'value': 'pending', 'label': 'Pending'},
      {'value': 'accepted', 'label': 'Accepted'},
      {'value': 'rejected', 'label': 'Rejected'},
      {'value': 'countered', 'label': 'Countered'},
      {'value': 'expired', 'label': 'Expired'},
    ],
    'sort_options': [
      {'value': 'newest', 'label': 'Newest'},
      {'value': 'oldest', 'label': 'Oldest'},
    ],
  },
};

/// `GET /talent/hiring-offers` test-env response (Apidog), without
/// `contract_configuration` and `offer`, which the app does not read.
Map<String, dynamic> _list() => {
  'success': true,
  'data': {
    'items': [
      {
        'id': 9,
        'reference': 'RI-2026-YQV3VMRE',
        'status': 'offer',
        'status_label': 'Offer',
        'contract_type': 'managed',
        'interview_required': true,
        'company': {'id': 1, 'name': 'Qader Technology', 'logo_url': null},
        'talent': {
          'id': 1,
          'talent_code': 'QDR-I29ZFD0M',
          'job_title': {'id': 3, 'name': 'Backend Developer'},
        },
        'offers': [
          {
            'id': 13,
            'proposed_by': 'talent',
            'salary_amount': '25000.0000',
            'currency': {
              'id': 1,
              'code': 'EGP',
              'symbol': 'E£',
              'name': 'Egyptian Pound',
            },
            'work_type': 'full_time',
            'work_mode': 'hybrid',
            'notice_period_days': 30,
            'status': 'pending',
            'status_label': 'Pending',
            'sent_at': '2026-11-18T09:43:18.000000Z',
            'created_at': '2026-11-18T09:43:18.000000Z',
          },
          {
            'id': 12,
            'proposed_by': 'client',
            'salary_amount': '20000.0000',
            'currency': {
              'id': 1,
              'code': 'EGP',
              'symbol': 'E£',
              'name': 'Egyptian Pound',
            },
            'work_type': 'full_time',
            'work_mode': 'hybrid',
            'notice_period_days': 30,
            'status': 'countered',
            'status_label': 'Countered',
            'sent_at': '2026-11-18T09:41:22.000000Z',
            'response_due_at': '2026-11-20T09:41:22.000000Z',
            'created_at': '2026-11-18T09:40:51.000000Z',
          },
        ],
        'interview': null,
        'available_actions': ['view'],
        'updated_at': '2026-11-18T09:41:22.000000Z',
      },
    ],
    'meta': {'current_page': 1, 'last_page': 1, 'per_page': 15, 'total': 1},
  },
};

class _Api extends Fake implements ApiConsumer {
  _Api(this.body, {this.failure});
  final Object? body;
  final Failure? failure;
  final paths = <String>[];
  final queries = <Map<String, dynamic>?>[];

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    paths.add(path);
    queries.add(queryParameters);
    if (failure case final failure?) return Left(failure);
    return Right(fromJson(body));
  }
}

void main() {
  test('loads the filter options in backend order', () async {
    final api = _Api(_options());
    final result = await ApiOffersRepository(api).loadOptions();
    expect(api.paths, ['/talent/hiring-offers/options']);
    final options = result.getOrThrow();
    expect(options.itemStatuses.map((o) => o.value), [
      'pending',
      'offer',
      'interview',
      'accepted',
      'on_hold',
      'rejected',
      'cancelled',
      'completed',
    ]);
    expect(options.itemStatuses[4].label, 'On Hold');
    expect(options.offerStatuses.map((o) => o.value), [
      'pending',
      'accepted',
      'rejected',
      'countered',
      'expired',
    ]);
    expect(options.sortOptions.map((o) => (o.value, o.label)), [
      ('newest', 'Newest'),
      ('oldest', 'Oldest'),
    ]);
  });

  test('skips malformed entries and falls back to the value', () async {
    final result = await ApiOffersRepository(
      _Api({
        'success': true,
        'data': {
          'item_statuses': [
            null,
            'offer',
            {'value': '', 'label': 'Empty'},
            {'value': 'interview'},
            {'value': 'accepted', 'label': '  '},
          ],
          'offer_statuses': 'not a list',
        },
      }),
    ).loadOptions();
    final options = result.getOrThrow();
    expect(options.itemStatuses.map((o) => (o.value, o.label)), [
      ('interview', 'interview'),
      ('accepted', 'accepted'),
    ]);
    expect(options.offerStatuses, isEmpty);
  });

  test('invalid shapes and network errors become failures', () async {
    for (final body in [
      null,
      'text',
      {'success': false, 'data': <String, dynamic>{}},
      {'success': true, 'data': null},
    ]) {
      final result = await ApiOffersRepository(_Api(body)).loadOptions();
      expect(result.getErrorOrThrow().message, 'offers_invalid_response');
    }
    final offline = await ApiOffersRepository(
      _Api(null, failure: const NetworkFailure(message: 'offline')),
    ).loadOptions();
    expect(offline.getErrorOrThrow(), isA<NetworkFailure>());
  });
  test('lists one page with status, sort and paging params', () async {
    final api = _Api(_list());
    final result = await ApiOffersRepository(api).loadOffers(
      const HiringOfferQuery(
        status: 'interview',
        sort: 'oldest',
        page: 2,
        perPage: 15,
      ),
    );
    expect(api.paths, ['/talent/hiring-offers']);
    expect(api.queries.single, {
      'page': 2,
      'per_page': 15,
      'status[]': 'interview',
      'sort': 'oldest',
    });
    final page = result.getOrThrow();
    expect((page.page, page.lastPage, page.total), (1, 1, 1));
    final offer = page.items.single;
    expect(offer.id, '9');
    expect(offer.reference, 'RI-2026-YQV3VMRE');
    expect((offer.status, offer.statusLabel), ('offer', 'Offer'));
    expect(offer.companyName, 'Qader Technology');
    expect(offer.companyLogoUrl, isNull);
    expect(offer.jobTitle, 'Backend Developer');
    // The newest offer in the history (the talent's counter).
    expect(offer.salary, 25000);
    expect(offer.currency, 'EGP');
    expect(offer.workMode, 'hybrid');
    // Received when the client first proposed.
    expect(offer.receivedAt, DateTime.utc(2026, 11, 18, 9, 41, 22).toLocal());
    expect(offer.actions, ['view']);
  });

  test('no filters send only paging; bad items are skipped', () async {
    final api = _Api({
      'success': true,
      'data': {
        'items': [
          null,
          {'status': 'offer'},
          {'id': 5, 'offers': 'none', 'company': 'x', 'talent': null},
        ],
        'meta': {'current_page': '2', 'last_page': 1},
      },
    });
    final page = (await ApiOffersRepository(
      api,
    ).loadOffers(const HiringOfferQuery())).getOrThrow();
    expect(api.queries.single, {'page': 1, 'per_page': 10});
    expect(page.items.single.id, '5');
    expect(page.items.single.salary, isNull);
    expect(page.items.single.receivedAt, isNull);
    expect(page.page, 2);
    expect(page.lastPage, 2);

    final invalid = await ApiOffersRepository(
      _Api({
        'success': true,
        'data': {'meta': <String, dynamic>{}},
      }),
    ).loadOffers(const HiringOfferQuery());
    expect(invalid.getErrorOrThrow().message, 'offers_invalid_response');
  });
}
