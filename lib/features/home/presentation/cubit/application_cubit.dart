import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/failure.dart';
import '../../data/application_repository.dart';
import '../../domain/talent_application.dart';

class ApplicationState {
  const ApplicationState({
    this.loading = false,
    this.application,
    this.failure,
  });
  final bool loading;
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
}
