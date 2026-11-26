import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/repositories/workspaces_repository.dart';

class WorkspacesState {
  const WorkspacesState({
    this.loading = false,
    this.workspaces = const [],
    this.failure,
  });
  final bool loading;
  final List<Workspace> workspaces;
  final Failure? failure;
}

/// The client's workspaces, for the screen that opens one.
class WorkspacesCubit extends Cubit<WorkspacesState> {
  WorkspacesCubit(this._repository)
    : super(const WorkspacesState(loading: true));
  final WorkspacesRepository _repository;

  Future<void> load() async {
    emit(WorkspacesState(loading: true, workspaces: state.workspaces));
    final result = await _repository.workspaces();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) =>
            WorkspacesState(failure: failure, workspaces: state.workspaces),
        (workspaces) => WorkspacesState(workspaces: workspaces),
      ),
    );
  }
}
