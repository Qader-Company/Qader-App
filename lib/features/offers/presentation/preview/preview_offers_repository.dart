import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/counter_offer.dart';
import '../../domain/entities/hiring_offer_details.dart';
import '../../domain/entities/hiring_offer_options.dart';
import '../../domain/entities/hiring_offer_summary.dart';
import '../../domain/entities/talent_offer.dart';
import '../../domain/repositories/offers_repository.dart';

/// Preview statuses: one per designed list chip. Labels are left empty so
/// the app translates `offers_status_<value>`.
enum PreviewOfferStatus {
  awaitingResponse,
  negotiating,
  interview,
  contracted,
  rejected,
  cancelled;

  static PreviewOfferStatus of(OfferStage stage) => switch (stage) {
    OfferStage.awaitingResponse => awaitingResponse,
    OfferStage.negotiating => negotiating,
    OfferStage.awaitingInterviewTimes ||
    OfferStage.interviewInProgress ||
    OfferStage.interviewCancelled ||
    OfferStage.interviewApologized => interview,
    OfferStage.contracted => contracted,
    OfferStage.rejectedByTalent => rejected,
    OfferStage.cancelledNoResponse => cancelled,
  };
}

/// Serves the sample [offers] like the API would, for logged-out and
/// preview routes. Preview data only: never real account data.
class PreviewOffersRepository implements OffersRepository {
  PreviewOffersRepository(List<TalentOffer> offers)
    : _offers = [...offers]
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  final List<TalentOffer> _offers;

  @override
  Future<Either<Failure, HiringOfferOptions>> loadOptions() async => Right(
    HiringOfferOptions(
      itemStatuses: [
        for (final status in PreviewOfferStatus.values)
          HiringOfferOption(value: status.name, label: ''),
      ],
      sortOptions: const [
        HiringOfferOption(value: 'newest', label: ''),
        HiringOfferOption(value: 'oldest', label: ''),
      ],
    ),
  );

  @override
  Future<Either<Failure, HiringOfferPage>> loadOffers(
    HiringOfferQuery query,
  ) async {
    final matches = [
      for (final offer in query.sort == 'oldest' ? _offers.reversed : _offers)
        if (query.status == null ||
            PreviewOfferStatus.of(offer.stage).name == query.status)
          offer,
    ];
    final lastPage = matches.isEmpty
        ? 1
        : (matches.length / query.perPage).ceil();
    final page = query.page.clamp(1, lastPage);
    return Right(
      HiringOfferPage(
        page: page,
        lastPage: lastPage,
        total: matches.length,
        items: [
          for (final offer
              in matches.skip((page - 1) * query.perPage).take(query.perPage))
            HiringOfferSummary(
              id: offer.id,
              status: PreviewOfferStatus.of(offer.stage).name,
              companyName: offer.company.name,
              jobTitle: offer.position,
              salary: offer.latest.salary,
              currency: offer.latest.currency,
              workMode: offer.latest.workMode,
              receivedAt: offer.receivedAt,
            ),
        ],
      ),
    );
  }

  /// Sample offers open the designed details screens instead.
  @override
  Future<Either<Failure, HiringOfferDetails>> loadOffer(String id) async =>
      const Left(ServerFailure(message: 'offers_invalid_response'));

  // Sample offers never call the API: their screens explain instead.
  @override
  Future<Either<Failure, void>> accept(String id) async =>
      const Left(ServerFailure(message: 'offers_action_failed'));

  @override
  Future<Either<Failure, void>> reject(String id) async =>
      const Left(ServerFailure(message: 'offers_action_failed'));

  @override
  Future<Either<Failure, void>> counter(String id, CounterOffer offer) async =>
      const Left(ServerFailure(message: 'offers_action_failed'));
}
