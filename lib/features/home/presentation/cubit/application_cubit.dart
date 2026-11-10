import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/repositories/application_repository.dart';
import '../../domain/talent_application.dart';

class ApplicationState {
  const ApplicationState({
    this.loading = false,
    this.submitting = false,
    this.application,
    this.failure,
  });
  final bool loading;

  /// A select / reject / cancel request is in flight.
  final bool submitting;
  final TalentApplication? application;
  final Failure? failure;
}

class ApplicationCubit extends Cubit<ApplicationState> {
  ApplicationCubit(this._repository)
    : super(const ApplicationState(loading: true));
  final ApplicationRepository _repository;

  Future<void> load() async {
    emit(ApplicationState(loading: true, application: state.application));
    final result = await _repository.load();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) =>
            ApplicationState(failure: failure, application: state.application),
        (application) => ApplicationState(application: application),
      ),
    );
  }

  /// Runs a talent action, then reloads the application so the screen
  /// follows the backend's new `screen_state`. Returns the failure, if any.
  Future<Failure?> _run(Future<Either<Failure, void>> Function() action) async {
    if (state.submitting) return null;
    emit(ApplicationState(submitting: true, application: state.application));
    final result = await action();
    if (isClosed) return null;
    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    emit(ApplicationState(application: state.application));
    // Reload either way: on failure the server state may still have moved.
    await load();
    return failure;
  }

  Future<Failure?> selectSlot(int slotId) =>
      _run(() => _repository.selectSlot(slotId));

  Future<Failure?> rejectSlots(String reason) =>
      _run(() => _repository.rejectSlots(reason));

  Future<Failure?> cancelInterview() => _run(_repository.cancelInterview);
}
