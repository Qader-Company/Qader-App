import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/counter_offer.dart';
import '../../domain/entities/hiring_offer_details.dart';
import '../../domain/repositories/offers_repository.dart';

class OfferDetailsState {
  const OfferDetailsState({
    this.loading = false,
    this.submitting = false,
    this.details,
    this.failure,
  });
  final bool loading;

  /// Accept, reject or counter is in flight.
  final bool submitting;
  final HiringOfferDetails? details;
  final Failure? failure;
}

/// One offer from `GET /talent/hiring-offers/{id}` and its actions.
class OfferDetailsCubit extends Cubit<OfferDetailsState> {
  OfferDetailsCubit(this._repository, this.id)
    : super(const OfferDetailsState(loading: true));
  final OffersRepository _repository;
  final String id;

  Future<void> load() async {
    emit(OfferDetailsState(loading: true, details: state.details));
    final result = await _repository.loadOffer(id);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) =>
            OfferDetailsState(failure: failure, details: state.details),
        (details) => OfferDetailsState(details: details),
      ),
    );
  }

  Future<Failure?> accept() => _run(() => _repository.accept(id));

  Future<Failure?> reject() => _run(() => _repository.reject(id));

  Future<Failure?> counter(CounterOffer offer) =>
      _run(() => _repository.counter(id, offer));

  /// Runs an action, then reloads the offer so the screen follows the
  /// backend's new status and actions. Returns the failure, if any.
  Future<Failure?> _run(Future<Either<Failure, void>> Function() action) async {
    if (state.submitting) return null;
    emit(OfferDetailsState(submitting: true, details: state.details));
    final result = await action();
    if (isClosed) return null;
    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    // Reload either way: on failure the server state may still have moved.
    await load();
    return failure;
  }
}
