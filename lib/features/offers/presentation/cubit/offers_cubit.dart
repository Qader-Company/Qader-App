import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/talent_offer.dart';

/// Status filter of the offers list; each groups one or more stages.
enum OfferStatusFilter {
  awaitingResponse,
  negotiating,
  interview,
  contracted,
  rejected,
  cancelled;

  static OfferStatusFilter of(OfferStage stage) => switch (stage) {
    OfferStage.awaitingResponse => awaitingResponse,
    OfferStage.negotiating => negotiating,
    OfferStage.awaitingInterviewTimes ||
    OfferStage.interviewInProgress ||
    OfferStage.interviewCancelled => interview,
    OfferStage.contracted => contracted,
    OfferStage.rejectedByTalent => rejected,
    OfferStage.cancelledNoResponse => cancelled,
  };
}

/// Received-date filter of the offers list.
enum OfferDateRange {
  all(null),
  last7Days(7),
  last30Days(30),
  last90Days(90);

  const OfferDateRange(this.days);
  final int? days;
}

class OffersState {
  const OffersState({
    this.offers = const [],
    this.query = '',
    this.status,
    this.dates = OfferDateRange.all,
    this.page = 1,
    this.visible = const [],
    this.pageCount = 1,
  });

  /// Every offer, newest first.
  final List<TalentOffer> offers;
  final String query;

  /// `null` shows every status.
  final OfferStatusFilter? status;
  final OfferDateRange dates;

  /// 1-based.
  final int page;

  /// The offers of [page] after search and filters.
  final List<TalentOffer> visible;
  final int pageCount;

  bool get filtered =>
      query.isNotEmpty || status != null || dates != OfferDateRange.all;
}

/// The offers list: search, status and date filters, and paging. Works on
/// a list in memory until the offers API is connected.
class OffersCubit extends Cubit<OffersState> {
  OffersCubit(List<TalentOffer> offers, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const OffersState()) {
    _apply(
      OffersState(
        offers: [...offers]
          ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt)),
      ),
    );
  }
  final DateTime Function() _now;
  static const pageSize = 4;

  void search(String query) => _apply(_copy(query: query.trim(), page: 1));

  void filterStatus(OfferStatusFilter? status) =>
      _apply(_copy(status: status, clearStatus: status == null, page: 1));

  void filterDates(OfferDateRange dates) =>
      _apply(_copy(dates: dates, page: 1));

  void clearFilters() => _apply(OffersState(offers: state.offers));

  void goTo(int page) => _apply(_copy(page: page));

  OffersState _copy({
    String? query,
    OfferStatusFilter? status,
    bool clearStatus = false,
    OfferDateRange? dates,
    int? page,
  }) => OffersState(
    offers: state.offers,
    query: query ?? state.query,
    status: clearStatus ? null : status ?? state.status,
    dates: dates ?? state.dates,
    page: page ?? state.page,
  );

  void _apply(OffersState next) {
    final query = next.query.toLowerCase();
    final days = next.dates.days;
    final since = days == null ? null : _now().subtract(Duration(days: days));
    final matches = [
      for (final offer in next.offers)
        if ((query.isEmpty ||
                offer.company.name.toLowerCase().contains(query) ||
                offer.position.toLowerCase().contains(query)) &&
            (next.status == null ||
                OfferStatusFilter.of(offer.stage) == next.status) &&
            (since == null || !offer.receivedAt.isBefore(since)))
          offer,
    ];
    final pageCount = matches.isEmpty ? 1 : (matches.length / pageSize).ceil();
    final page = next.page.clamp(1, pageCount);
    final start = (page - 1) * pageSize;
    emit(
      OffersState(
        offers: next.offers,
        query: next.query,
        status: next.status,
        dates: next.dates,
        page: page,
        pageCount: pageCount,
        visible: matches.skip(start).take(pageSize).toList(),
      ),
    );
  }
}
