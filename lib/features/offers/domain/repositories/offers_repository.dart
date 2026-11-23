import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../entities/counter_offer.dart';
import '../entities/hiring_offer_details.dart';
import '../entities/hiring_offer_options.dart';
import '../entities/hiring_offer_summary.dart';

/// The talent's hiring offers.
abstract class OffersRepository {
  /// `GET /talent/hiring-offers/options`: filter choices.
  Future<Either<Failure, HiringOfferOptions>> loadOptions();

  /// `GET /talent/hiring-offers`: one page of the list.
  Future<Either<Failure, HiringOfferPage>> loadOffers(HiringOfferQuery query);

  /// `GET /talent/hiring-offers/{id}`: one offer with its history.
  Future<Either<Failure, HiringOfferDetails>> loadOffer(String id);

  /// `POST /talent/hiring-offers/{id}/accept`.
  Future<Either<Failure, void>> accept(String id);

  /// `POST /talent/hiring-offers/{id}/reject`.
  Future<Either<Failure, void>> reject(String id);

  /// `POST /talent/hiring-offers/{id}/counter`.
  Future<Either<Failure, void>> counter(String id, CounterOffer offer);

  /// `POST /talent/hiring-interviews/{interviewId}/accept-schedule`.
  Future<Either<Failure, void>> acceptInterviewTime(String interviewId);

  /// `POST /talent/hiring-interviews/{interviewId}/request-schedule-change`
  /// with the talent's [reason].
  Future<Either<Failure, void>> requestInterviewChange(
    String interviewId,
    String reason,
  );

  /// `POST /talent/hiring-interviews/{interviewId}/apologize` with the
  /// talent's [reason].
  Future<Either<Failure, void>> apologizeForInterview(
    String interviewId,
    String reason,
  );
}
