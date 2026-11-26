import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/workspace_dashboard.dart';
import '../../domain/repositories/workspaces_repository.dart';

class WorkspaceDashboardState {
  const WorkspaceDashboardState({
    this.loading = false,
    this.dashboard,
    this.failure,
  });
  final bool loading;
  final WorkspaceDashboard? dashboard;
  final Failure? failure;
}

class WorkspaceDashboardCubit extends Cubit<WorkspaceDashboardState> {
  WorkspaceDashboardCubit(this._repository, this.workspaceId)
    : super(const WorkspaceDashboardState(loading: true));
  final WorkspacesRepository _repository;
  final String workspaceId;

  Future<void> load() async {
    emit(WorkspaceDashboardState(loading: true, dashboard: state.dashboard));
    final result = await _repository.dashboard(workspaceId);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => WorkspaceDashboardState(
          failure: failure,
          dashboard: state.dashboard,
        ),
        (dashboard) => WorkspaceDashboardState(dashboard: dashboard),
      ),
    );
  }
}
