import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/entities/workspace_draft.dart';
import '../../domain/entities/workspace_lookup.dart';
import '../../domain/repositories/workspaces_repository.dart';

class CreateWorkspaceState {
  const CreateWorkspaceState({
    this.loadingLookups = false,
    this.industries = const [],
    this.countries = const [],
    this.cities = const [],
    this.loadingCities = false,
    this.submitting = false,
    this.created,
    this.failure,
  });
  final bool loadingLookups;
  final List<WorkspaceLookup> industries;
  final List<WorkspaceLookup> countries;
  final List<WorkspaceLookup> cities;
  final bool loadingCities;
  final bool submitting;

  /// Set once the workspace exists.
  final Workspace? created;
  final Failure? failure;

  CreateWorkspaceState copyWith({
    bool? loadingLookups,
    List<WorkspaceLookup>? industries,
    List<WorkspaceLookup>? countries,
    List<WorkspaceLookup>? cities,
    bool? loadingCities,
    bool? submitting,
    Workspace? created,
    Failure? failure,
    bool clearFailure = false,
  }) => CreateWorkspaceState(
    loadingLookups: loadingLookups ?? this.loadingLookups,
    industries: industries ?? this.industries,
    countries: countries ?? this.countries,
    cities: cities ?? this.cities,
    loadingCities: loadingCities ?? this.loadingCities,
    submitting: submitting ?? this.submitting,
    created: created ?? this.created,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

/// Lists for the "Create Your Workspace" form and its submission.
class CreateWorkspaceCubit extends Cubit<CreateWorkspaceState> {
  CreateWorkspaceCubit(this._repository)
    : super(const CreateWorkspaceState(loadingLookups: true));
  final WorkspacesRepository _repository;
  int _citiesRequest = 0;

  Future<void> loadLookups() async {
    emit(state.copyWith(loadingLookups: true, clearFailure: true));
    final industries = await _repository.industries();
    final countries = await _repository.countries();
    if (isClosed) return;
    final failure = industries.isError
        ? industries.getErrorOrThrow()
        : countries.isError
        ? countries.getErrorOrThrow()
        : null;
    emit(
      state.copyWith(
        loadingLookups: false,
        industries: industries.isError ? null : industries.getOrThrow(),
        countries: countries.isError ? null : countries.getOrThrow(),
        failure: failure,
      ),
    );
  }

  /// Cities of the chosen country; a later choice wins over a slow answer.
  Future<void> selectCountry(int countryId) async {
    final request = ++_citiesRequest;
    emit(state.copyWith(cities: const [], loadingCities: true));
    final result = await _repository.cities(countryId);
    if (isClosed || request != _citiesRequest) return;
    emit(
      result.fold(
        (failure) => state.copyWith(loadingCities: false, failure: failure),
        (cities) => state.copyWith(loadingCities: false, cities: cities),
      ),
    );
  }

  Future<void> submit(WorkspaceDraft draft) async {
    if (state.submitting || state.created != null) return;
    emit(state.copyWith(submitting: true, clearFailure: true));
    final result = await _repository.create(draft);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => state.copyWith(submitting: false, failure: failure),
        (workspace) => state.copyWith(submitting: false, created: workspace),
      ),
    );
  }
}
