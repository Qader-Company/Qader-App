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
    this.sortOptions = const [],
    this.items = const [],
    this.status,
    this.sort,
    this.page = 1,
    this.lastPage = 1,
  });

  /// A page request is in flight.
  final bool loading;

  /// The last page request failed; [items] keeps the previous page.
  final Failure? failure;

  /// Status filter choices (`item_statuses`).
  final List<HiringOfferOption> statuses;

  /// Date order choices (`sort_options`).
  final List<HiringOfferOption> sortOptions;
  final List<HiringOfferSummary> items;

  /// Selected `item_statuses` value; `null` for every status.
  final String? status;

  /// Selected `sort_options` value; `null` for the server default
  /// ("All Dates").
  final String? sort;
  final int page, lastPage;

  bool get filtered => status != null || sort != null;

  OffersState copyWith({
    bool? loading,
    Object? failure = _keep,
    List<HiringOfferOption>? statuses,
    List<HiringOfferOption>? sortOptions,
    List<HiringOfferSummary>? items,
    Object? status = _keep,
    Object? sort = _keep,
    int? page,
    int? lastPage,
  }) => OffersState(
    loading: loading ?? this.loading,
    failure: identical(failure, _keep) ? this.failure : failure as Failure?,
    statuses: statuses ?? this.statuses,
    sortOptions: sortOptions ?? this.sortOptions,
    items: items ?? this.items,
    status: identical(status, _keep) ? this.status : status as String?,
    sort: identical(sort, _keep) ? this.sort : sort as String?,
    page: page ?? this.page,
    lastPage: lastPage ?? this.lastPage,
  );
}

/// The offers list: the server filters, sorts and pages it.
class OffersCubit extends Cubit<OffersState> {
  OffersCubit(this._repository, {this.perPage = 10})
    : super(const OffersState(loading: true));
  final OffersRepository _repository;
  final int perPage;

  /// Only the newest page request may update the state.
  int _request = 0;

  /// Filter options and the first page.
  Future<void> start() => Future.wait([_loadOptions(), _load(page: 1)]);

  /// Everything again, e.g. after the language changed (labels are
  /// localized by the backend).
  Future<void> reload() =>
      Future.wait([_loadOptions(), _load(page: state.page)]);

  Future<void> filterStatus(String? status) {
    emit(state.copyWith(status: status));
    return _load(page: 1);
  }

  Future<void> sortBy(String? sort) {
    emit(state.copyWith(sort: sort));
    return _load(page: 1);
  }

  Future<void> clearFilters() {
    emit(state.copyWith(status: null, sort: null));
    return _load(page: 1);
  }

  Future<void> goTo(int page) => _load(page: page);

  Future<void> retry() => reload();

  Future<void> _loadOptions() async {
    final result = await _repository.loadOptions();
    if (isClosed) return;
    // Without options the menus only offer "All Statuses" / "All Dates".
    result.fold(
      (_) {},
      (options) => emit(
        state.copyWith(
          statuses: options.itemStatuses,
          sortOptions: options.sortOptions,
        ),
      ),
    );
  }

  Future<void> _load({required int page}) async {
    final request = ++_request;
    emit(state.copyWith(loading: true, failure: null));
    final result = await _repository.loadOffers(
      HiringOfferQuery(
        status: state.status,
        sort: state.sort,
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
}
