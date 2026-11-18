import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/hiring_offer_options.dart';
import '../../domain/entities/hiring_offer_summary.dart';
import '../../domain/repositories/offers_repository.dart';

const _keep = Object();

class OffersState {
  const OffersState({
    this.loading = false,
    this.failure,
    this.statuses = const [],
    this.items = const [],
    this.query = '',
    this.status,
    this.page = 1,
    this.lastPage = 1,
  });

  /// A page request is in flight.
  final bool loading;

  /// The last page request failed; [items] keeps the previous page.
  final Failure? failure;

  /// Status filter choices (`item_statuses`).
  final List<HiringOfferOption> statuses;
  final List<HiringOfferSummary> items;
  final String query;

  /// Selected `item_statuses` value; `null` for every status.
  final String? status;
  final int page, lastPage;

  bool get filtered => query.isNotEmpty || status != null;

  OffersState copyWith({
    bool? loading,
    Object? failure = _keep,
    List<HiringOfferOption>? statuses,
    List<HiringOfferSummary>? items,
    String? query,
    Object? status = _keep,
    int? page,
    int? lastPage,
  }) => OffersState(
    loading: loading ?? this.loading,
    failure: identical(failure, _keep) ? this.failure : failure as Failure?,
    statuses: statuses ?? this.statuses,
    items: items ?? this.items,
    query: query ?? this.query,
    status: identical(status, _keep) ? this.status : status as String?,
    page: page ?? this.page,
    lastPage: lastPage ?? this.lastPage,
  );
}

/// The offers list: the server searches, filters and pages it.
class OffersCubit extends Cubit<OffersState> {
  OffersCubit(
    this._repository, {
    this.perPage = 10,
    this.searchDelay = const Duration(milliseconds: 400),
  }) : super(const OffersState(loading: true));
  final OffersRepository _repository;
  final int perPage;

  /// Typing pause before the search request.
  final Duration searchDelay;
  Timer? _searchTimer;

  /// Only the newest page request may update the state.
  int _request = 0;

  /// Filter options and the first page.
  Future<void> start() => Future.wait([_loadOptions(), _load(page: 1)]);

  /// Everything again, e.g. after the language changed (labels are
  /// localized by the backend).
  Future<void> reload() =>
      Future.wait([_loadOptions(), _load(page: state.page)]);

  void search(String query) {
    _searchTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed == state.query) return;
    _searchTimer = Timer(searchDelay, () {
      if (isClosed) return;
      emit(state.copyWith(query: trimmed));
      _load(page: 1);
    });
  }

  Future<void> filterStatus(String? status) {
    emit(state.copyWith(status: status));
    return _load(page: 1);
  }

  Future<void> clearFilters() {
    _searchTimer?.cancel();
    emit(state.copyWith(query: '', status: null));
    return _load(page: 1);
  }

  Future<void> goTo(int page) => _load(page: page);

  Future<void> retry() => reload();

  Future<void> _loadOptions() async {
    final result = await _repository.loadOptions();
    if (isClosed) return;
    // Without options the filter only offers "All Statuses".
    result.fold(
      (_) {},
      (options) => emit(state.copyWith(statuses: options.itemStatuses)),
    );
  }

  Future<void> _load({required int page}) async {
    final request = ++_request;
    emit(state.copyWith(loading: true, failure: null));
    final result = await _repository.loadOffers(
      HiringOfferQuery(
        search: state.query,
        status: state.status,
        page: page < 1 ? 1 : page,
        perPage: perPage,
      ),
    );
    if (isClosed || request != _request) return;
    emit(
      result.fold(
        (failure) => state.copyWith(loading: false, failure: failure),
        (page) => state.copyWith(
          loading: false,
          items: page.items,
          page: page.page,
          lastPage: page.lastPage,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }
}
