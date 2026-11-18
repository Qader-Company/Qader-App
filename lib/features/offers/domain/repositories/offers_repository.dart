import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/hiring_offer_options.dart';
import '../entities/hiring_offer_summary.dart';

/// The talent's hiring offers.
abstract class OffersRepository {
  /// `GET /talent/hiring-offers/options`: filter choices.
  Future<Either<Failure, HiringOfferOptions>> loadOptions();

  /// `GET /talent/hiring-offers`: one page of the list.
  Future<Either<Failure, HiringOfferPage>> loadOffers(HiringOfferQuery query);
}
