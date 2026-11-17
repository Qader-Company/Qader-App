import 'package:flutter_test/flutter_test.dart';
import 'package:qader/features/offers/domain/entities/talent_offer.dart';
import 'package:qader/features/offers/presentation/cubit/offers_cubit.dart';
import 'package:qader/features/offers/presentation/preview/offers_preview_data.dart';

void main() {
  OffersCubit cubit() =>
      OffersCubit(OffersPreviewData.offers, now: () => DateTime(2026, 11, 17));

  test('pages the offers newest first, four per page', () async {
    final offers = cubit();
    addTearDown(offers.close);
    expect(offers.state.pageCount, 3);
    expect(offers.state.visible.map((o) => o.id), ['1', '2', '3', '4']);
    offers.goTo(2);
    expect(offers.state.page, 2);
    expect(offers.state.visible.map((o) => o.id), ['5', '9', '6', '8']);
    offers.goTo(9);
    expect(offers.state.page, 3);
    expect(offers.state.visible.map((o) => o.id), ['7']);
  });

  test('search matches company or position, case-insensitively', () async {
    final offers = cubit();
    addTearDown(offers.close);
    offers.goTo(2);
    offers.search('  react ');
    expect(offers.state.page, 1);
    expect(offers.state.visible.single.position, 'React Developer');
    expect(offers.state.filtered, isTrue);
    offers.search('techcorp');
    expect(offers.state.visible, hasLength(4));
    offers.search('nobody');
    expect(offers.state.visible, isEmpty);
    expect(offers.state.pageCount, 1);
  });

  test('status and date filters combine; clear resets them', () async {
    final offers = cubit();
    addTearDown(offers.close);
    offers.filterStatus(OfferStatusFilter.interview);
    expect(offers.state.visible.map((o) => o.stage), [
      OfferStage.awaitingInterviewTimes,
      OfferStage.interviewInProgress,
      OfferStage.interviewCancelled,
      OfferStage.interviewApologized,
    ]);
    offers.filterDates(OfferDateRange.last30Days);
    expect(offers.state.visible.map((o) => o.id), ['3', '4', '5']);
    offers.filterDates(OfferDateRange.last7Days);
    expect(offers.state.visible, isEmpty);
    offers.filterStatus(null);
    expect(offers.state.visible.map((o) => o.id), ['1', '2']);
    offers.clearFilters();
    expect(offers.state.filtered, isFalse);
    expect(offers.state.visible, hasLength(4));
    expect(offers.state.pageCount, 3);
  });

  test('every status filter matches at least one preview offer', () {
    for (final status in OfferStatusFilter.values) {
      expect(
        OffersPreviewData.offers.any(
          (offer) => OfferStatusFilter.of(offer.stage) == status,
        ),
        isTrue,
        reason: status.name,
      );
    }
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
