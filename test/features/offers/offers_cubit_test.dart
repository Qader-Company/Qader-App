import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/offers/domain/entities/hiring_offer_options.dart';
import 'package:qader/features/offers/domain/entities/hiring_offer_summary.dart';
import 'package:qader/features/offers/domain/entities/talent_offer.dart';
import 'package:qader/features/offers/domain/repositories/offers_repository.dart';
import 'package:qader/features/offers/presentation/cubit/offers_cubit.dart';
import 'package:qader/features/offers/presentation/preview/offers_preview_data.dart';
import 'package:qader/features/offers/presentation/preview/preview_offers_repository.dart';

/// Records every list request; answers from [pages] or fails.
class _Repo implements OffersRepository {
  final queries = <HiringOfferQuery>[];
  Failure? failure;
  Completer<void>? gate;

  @override
  Future<Either<Failure, HiringOfferOptions>> loadOptions() async =>
      const Right(
        HiringOfferOptions(
          itemStatuses: [
            HiringOfferOption(value: 'offer', label: 'Offer'),
            HiringOfferOption(value: 'interview', label: 'Interview'),
          ],
        ),
      );

  @override
  Future<Either<Failure, HiringOfferPage>> loadOffers(
    HiringOfferQuery query,
  ) async {
    queries.add(query);
    await gate?.future;
    if (failure case final failure?) return Left(failure);
    return Right(
      HiringOfferPage(
        page: query.page,
        lastPage: 3,
        items: [
          HiringOfferSummary(
            id: '${query.page}',
            status: query.status ?? 'offer',
          ),
        ],
      ),
    );
  }
}

void main() {
  test('starts with the options and the first page', () async {
    final repo = _Repo();
    final offers = OffersCubit(repo, perPage: 15);
    addTearDown(offers.close);
    expect(offers.state.loading, isTrue);
    await offers.start();
    expect(offers.state.loading, isFalse);
    expect(offers.state.statuses.map((o) => o.value), ['offer', 'interview']);
    expect(offers.state.items.single.id, '1');
    expect(offers.state.lastPage, 3);
    expect(repo.queries.single.perPage, 15);
    expect(repo.queries.single.page, 1);
  });

  test('status, paging and clear send the right queries', () async {
    final repo = _Repo();
    final offers = OffersCubit(repo);
    addTearDown(offers.close);
    await offers.start();
    await offers.goTo(2);
    expect(offers.state.page, 2);
    await offers.filterStatus('interview');
    expect(repo.queries.last.status, 'interview');
    expect(repo.queries.last.page, 1);
    expect(offers.state.filtered, isTrue);
    await offers.clearFilters();
    expect(repo.queries.last.status, isNull);
    expect(offers.state.filtered, isFalse);
  });

  test('search waits for a typing pause and starts at page 1', () async {
    final repo = _Repo();
    final offers = OffersCubit(
      repo,
      searchDelay: const Duration(milliseconds: 20),
    );
    addTearDown(offers.close);
    await offers.start();
    await offers.goTo(3);
    offers.search('so');
    offers.search(' software ');
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(repo.queries.where((q) => q.search.isNotEmpty), hasLength(1));
    expect(repo.queries.last.search, 'software');
    expect(repo.queries.last.page, 1);
    expect(offers.state.query, 'software');
  });

  test(
    'a failure keeps the previous page; stale answers are ignored',
    () async {
      final repo = _Repo();
      final offers = OffersCubit(repo);
      addTearDown(offers.close);
      await offers.start();
      repo.failure = const NetworkFailure(message: 'offline');
      await offers.goTo(2);
      expect(offers.state.failure, isA<NetworkFailure>());
      expect(offers.state.items.single.id, '1');

      repo.failure = null;
      final gate = repo.gate = Completer<void>();
      final slow = offers.goTo(2);
      repo.gate = null;
      await offers.goTo(3);
      expect(offers.state.items.single.id, '3');
      // The older request finishes last and must not overwrite page 3.
      gate.complete();
      await slow;
      expect(offers.state.items.single.id, '3');
      expect(offers.state.page, 3);
    },
  );

  test('the preview repository searches, filters and pages samples', () async {
    final repo = PreviewOffersRepository(OffersPreviewData.offers);
    final all = (await repo.loadOffers(
      const HiringOfferQuery(perPage: 4),
    )).getOrThrow();
    expect(all.lastPage, 3);
    expect(all.items.map((o) => o.id), ['1', '2', '3', '4']);
    final interviews = (await repo.loadOffers(
      const HiringOfferQuery(status: 'interview'),
    )).getOrThrow();
    expect(interviews.items.map((o) => o.id), ['3', '4', '5', '9']);
    final search = (await repo.loadOffers(
      const HiringOfferQuery(search: 'REACT'),
    )).getOrThrow();
    expect(search.items.single.jobTitle, 'React Developer');
    final options = (await repo.loadOptions()).getOrThrow();
    expect(
      options.itemStatuses.map((o) => o.value),
      PreviewOfferStatus.values.map((s) => s.name),
    );
    for (final stage in OfferStage.values) {
      expect(
        OffersPreviewData.offers.any((offer) => offer.stage == stage),
        isTrue,
        reason: stage.name,
      );
    }
  });

  test('company cancellation keeps the interview step; apology fails it', () {
    expect(OfferStage.interviewCancelled.progressStep, 1);
    expect(OfferStage.interviewCancelled.failed, isFalse);
    expect(OfferStage.interviewApologized.progressStep, 1);
    expect(OfferStage.interviewApologized.failed, isTrue);
  });
}
