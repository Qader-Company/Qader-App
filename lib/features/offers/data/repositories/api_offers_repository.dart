import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
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
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.status case final status?) 'status[]': status,
      },
    );
    return data.fold(
      Left.new,
      (data) => data['items'] is List
          ? Right(HiringOfferPage.fromJson(data))
          : const Left(ServerFailure(message: 'offers_invalid_response')),
    );
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
