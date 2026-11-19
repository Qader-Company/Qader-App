import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/counter_offer.dart';
import '../../domain/entities/hiring_offer_details.dart';
import '../../domain/entities/hiring_offer_options.dart';
import '../../domain/entities/hiring_offer_summary.dart';
import '../../domain/repositories/offers_repository.dart';

class ApiOffersRepository implements OffersRepository {
  const ApiOffersRepository(this._api);
  final ApiConsumer _api;
  static const listPath = '/talent/hiring-offers';
  static const optionsPath = '/talent/hiring-offers/options';

  @override
  Future<Either<Failure, HiringOfferOptions>> loadOptions() async {
    final data = await _data(optionsPath);
    return data.fold(
      Left.new,
      (data) => Right(HiringOfferOptions.fromJson(data)),
    );
  }

  /// `status` is an array parameter; Laravel reads `status[]=offer`.
  @override
  Future<Either<Failure, HiringOfferPage>> loadOffers(
    HiringOfferQuery query,
  ) async {
    final data = await _data(
      listPath,
      query: {
        'page': query.page,
        'per_page': query.perPage,
        if (query.status case final status?) 'status[]': status,
        if (query.sort case final sort?) 'sort': sort,
      },
    );
    return data.fold(
      Left.new,
      (data) => data['items'] is List
          ? Right(HiringOfferPage.fromJson(data))
          : const Left(ServerFailure(message: 'offers_invalid_response')),
    );
  }

  @override
  Future<Either<Failure, HiringOfferDetails>> loadOffer(String id) async {
    final data = await _data('$listPath/${Uri.encodeComponent(id)}');
    return data.fold(Left.new, (data) {
      final details = HiringOfferDetails.fromJson(data);
      return details == null
          ? const Left(ServerFailure(message: 'offers_invalid_response'))
          : Right(details);
    });
  }

  @override
  Future<Either<Failure, void>> accept(String id) => _action(id, 'accept');

  @override
  Future<Either<Failure, void>> reject(String id) => _action(id, 'reject');

  @override
  Future<Either<Failure, void>> counter(String id, CounterOffer offer) =>
      _action(id, 'counter', data: counterBody(offer));

  /// JSON body of Send Counter Offer.
  static Map<String, dynamic> counterBody(CounterOffer offer) => {
    'salary_amount': offer.salary,
    if (offer.currencyId case final id?) 'currency_id': id,
    if (offer.workType case final type?) 'work_type': type,
    'work_mode': offer.workMode,
    if (_dayName(offer.firstWorkday) case final day?) 'work_start_day': day,
    if (_dayName(offer.lastWorkday) case final day?) 'work_end_day': day,
    if (offer.workMode == 'hybrid')
      'hybrid_work_days': [
        for (final day in offer.hybridDays)
          if (_dayName(day) case final name?) name,
      ],
    if (offer.hoursPerDay case final hours?) 'work_hours': hours,
    'notice_period_days': offer.noticeDays,
    'work_location': offer.location,
  };

  static const _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  static String? _dayName(int? weekday) =>
      weekday == null || weekday < 1 || weekday > 7 ? null : _days[weekday - 1];

  Future<Either<Failure, void>> _action(
    String id,
    String action, {
    Object? data,
  }) async {
    final result = await _api.post<Object?>(
      '$listPath/${Uri.encodeComponent(id)}/$action',
      data: data,
      contentType: data == null ? null : 'application/json',
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true) {
      final message = raw is Map ? raw['message'] : null;
      return Left(
        ServerFailure(
          message: message is String && message.trim().isNotEmpty
              ? message
              : 'offers_action_failed',
        ),
      );
    }
    return const Right(null);
  }

  /// The `data` object of a successful response.
  Future<Either<Failure, Map<String, dynamic>>> _data(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final result = await _api.get<Object?>(
      path,
      queryParameters: query,
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true || raw['data'] is! Map) {
      return const Left(ServerFailure(message: 'offers_invalid_response'));
    }
    return Right(Map<String, dynamic>.from(raw['data'] as Map));
  }
}
